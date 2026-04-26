extern int main();

unsigned char *eot = (unsigned char *)0xf000;
void eot_seq()
{
    *eot = 0xff;
    return;
}

void _start(void)
{
	main();
  eot_seq();
	return;
}
