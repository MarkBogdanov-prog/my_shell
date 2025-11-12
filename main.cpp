#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <unistd.h>
#include <sys/wait.h>
#include <csignal>
#include <cstring>

using namespace std;

volatile sig_atomic_t got_sighup = 0;

void sighup_handler(int sig) {
    got_sighup = 1; 
}

void setup_signal_handler() {
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = sighup_handler;
    sa.sa_flags = SA_RESTART;
    sigaction(SIGHUP, &sa, NULL);
}

void handle_debug(string input) {
    input = input.substr(5);
    while (!input.empty() && input[0] == ' ') {
        input.erase(0, 1);
    }
    cout << input << '\n';
}

void handle_env(string input) {
    size_t pos = input.find("\\e") + 3;
    
    if (pos < input.length()) {
        string var_name = input.substr(pos);
        
        if (!var_name.empty() && var_name[0] == '$') 
            var_name = var_name.substr(1);
        
        const char* env_value = getenv(var_name.c_str());
        if (env_value != nullptr) {
            string value = env_value;
            size_t start = 0;
            size_t end = value.find(':');
            
            while (end != string::npos) {
                cout << value.substr(start, end - start) << '\n';
                start = end + 1;
                end = value.find(':', start);
            }
            cout << value.substr(start) << '\n';
        } else {
            cout << "Environment variable '" << var_name << "' not found" << '\n';
        }
    } else {
        cout << "Usage: \\e $VARIABLE" << '\n';
    }
}

void handle_external_command(string input) {
    pid_t pid = fork();
    
    if (pid == 0) {
        vector<string> args;
        stringstream ss(input);
        string token;
        
        while (ss >> token) {
            args.push_back(token);
        }
        
        vector<char*> argv;
        for (auto& arg : args) {
            argv.push_back(const_cast<char*>(arg.c_str()));
        }
        argv.push_back(nullptr);
        
        execvp(argv[0], argv.data());
        
        cout << input << ": command not found\n";
        exit(1);
        
    } else if (pid > 0) {
        int status;
        waitpid(pid, &status, 0);
    } else {
        cerr << "Failed to create process" << '\n';
    }
}

int main() {
    setup_signal_handler();

    string hist = "kubsh_history.txt";
    ofstream F(hist, ios::app);

    cerr << "$ ";

    string input;
    while (getline(cin, input)) {
        if (got_sighup) {
            cout << "Configuration reloaded" << endl; 
            got_sighup = 0;
            cerr << "$ ";
            continue;
        }
        
        F << '$' << input << '\n';  
        F.flush(); 
        
        if (input == "\\q") 
            break;
        
        if (input.empty()) {
            cerr << "$ ";
            continue;
        }
        
        if (input.find("debug") == 0) {
            handle_debug(input);
        } else if (input.find("\\e") == 0) {
            handle_env(input);
        } else {
            handle_external_command(input);
        }

        cerr << "$ ";
    }
    return 0;
}
