#include <iostream>
#include <fstream>

int main() {
    std::string filename;
    std::cout << "Input file name ";
    std::cin >> filename;

    std::ifstream inputFile(filename);
    if (!inputFile)
    {
        std::cerr << "Can not open " << filename << std::endl;
        return 1;
    }

    std::string outputFilename = filename + "_output.hex";
    std::ofstream outputFile(outputFilename);
    if (!outputFile)
    {
        std::cerr << "could not create file " << outputFilename << std::endl;
        return 1;
    }

    std::string line, w1, w2, w3, w4;

    while (std::getline(inputFile, line))
    {
        w1 = line.substr(0, 2);
        w2 = line.substr(2, 2);
        w3 = line.substr(4, 2);
        w4 = line.substr(6, 2);
        outputFile << w4 << "\n";
        outputFile << w3 << "\n";
        outputFile << w2 << "\n";
        outputFile << w1 << "\n";
    }

    inputFile.close();
    outputFile.close();

    std::cout << "Process done! output to " << outputFilename << std::endl;

    return 0;
}