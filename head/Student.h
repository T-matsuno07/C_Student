#ifndef __STUDENT_H_
#define __STUDENT_H_

#include <stdio.h>

typedef struct {
  char *name;
  int jap;
  int math;
  int eng;
}Student;

void Student_init(Student *);


#endif





