// Compile with: g++ -fPIC -shared doubling.cpp -o libdoubling.so
extern "C" {
    void doubling(double* input, int n, double* output) {
        for (int i = 0; i < n; i++) {
            output[i] = 2.0 * input[i];
        }
    }
}