#include <stdio.h>
#include "Student.h"
/* main method */
int main(int argc, char **argv){
  int localA = 0;
  Student a;
  Student b;
  Student_init(&a);
  Student_init(&b);
  b.jap = 0;
  printf("Hello world!  %d \n", localA );
  return 0;
}

