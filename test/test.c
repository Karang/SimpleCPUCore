int strlen(char* c) {
	int i = 0;
	while (*(c+i)) i++;
	return i;
}

int mult(int a, int b) {
	if (a==1) return b;
	if (a&1) return (mult(a>>1, b)<<1) + b;
	return mult(a>>1, b)<<1;
}

int main() {
	char c[] = "helloworld";
	int a = strlen(c);
    int i = mult(a, 3);
	if (i==30) return 0;
    return 1;
}
