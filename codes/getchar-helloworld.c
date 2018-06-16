void main(void)
{
  char name[100];
  int i=0;
  while((name[i] = getchar())!='\n' && i<80)
        i++ ;
  name[i]=0;
  strcat(name,", hello world!");
  puts(name);
}
