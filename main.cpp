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
        
        cout << input << endl;
    }
    return 0;
}
