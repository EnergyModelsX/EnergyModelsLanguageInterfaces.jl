#ifdef __cplusplus
extern "C" {
#endif
// Compile with: gcc -fPIC -shared doubling.c -o libdoubling.so
void doubling(double* input, int n, double* output) {
    for (int i = 0; i < n; i++) {
        output[i] = 2.0 * input[i];
    }
}

#ifdef __cplusplus
}
#endif