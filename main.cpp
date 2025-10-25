#include <iostream>
#include <fstream>
#include <string>

using namespace std;

int main() {
    string hist = "kubsh_history.txt";
    ofstream F(hist, ios::app);

    string input;
    while (getline(cin, input)) {
        F << '$' << input << '\n';  
        F.flush();
        
        if (input == "\\q") 
            break;
        
        if (input.find("echo") == 0) {
            string echo_text = input.substr(4);
            while (!echo_text.empty() && echo_text[0] == ' ') {
                echo_text.erase(0, 1);
            }
            cout << echo_text << '\n';
        } else {
            cout << input << endl;
        }
    }
    return 0;
}
