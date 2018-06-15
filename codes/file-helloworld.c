#include <stdio.h>
void main(void){
  FILE *fp;
  fp = fopen("file-helloworld.txt", "w");
  fputs("hello world!",fp);
  fclose(fp);
}
