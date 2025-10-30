
#include <iostream>
#include <fstream>
#include <string>

using namespace std;

void handle_debug(string input) {
    input = input.substr(5);
    while (!input.empty() && input[0] == ' ') {
        input.erase(0, 1);
    }
    cout << input << '\n';
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
        } else {
            cout << "Unknown command: " << input << '\n';
        }

        cerr << "$ ";
    }
    return 0;
}
