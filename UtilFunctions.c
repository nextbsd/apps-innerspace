#include <stdlib.h>

#define RAND ((float)rand()/(float)RAND_MAX)
 
float randBetween(float lower, float upper)
{
  float result = 0.0;
  
  if (lower > upper) 
    {
      float temp = 0.0;
      temp = lower; lower = upper; upper = temp;
    }
  result = ((upper - lower) * RAND + lower);
  // printf("upper = %f, lower = %f, result = %f\n",upper,lower,result);
  return result;
}

/*
int main()
{
  int i = 0;
  for(i = 0; i < 10; i++)
    {
      float r = randBetween(-20,20);
      printf("%f\n",r);
    }
}
*/
