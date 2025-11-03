#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <cstdlib>

using namespace std;

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

int main() {
    string hist = "kubsh_history.txt";
    ofstream F(hist, ios::app);

    cerr << "$ ";

    string input;
    while (getline(cin, input)) {
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
            cout << "Unknown command: " << input << '\n';
        }

        cerr << "$ ";
    }
    return 0;
}

