#include <stdio.h>
#include <stdlib.h>
#include "Student.h"

void Student_init(Student *arg){
  printf("Called Student_init function \n");
  arg->name = (char *)malloc(256);
  arg->jap = 0;
  arg->math = 0;
  return;
}
