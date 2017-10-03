
int main(void) {
	char c[] = "helloworld";	
	int i = 0;
	while (*(c+i)) i++;
	if (i==10) return 0;
	return 1;
}
