#include <stdlib.h>

#ifdef GNUSTEP
#define BOOL XWINDOWSBOOL	// prevent X windows BOOL
#include <X11/Xlib.h>		// warning
#undef BOOL
#endif

void makeWindowOmniPresent(int windowNumber)
{
#ifdef GNUSTEP
  printf("Window number is %d",windowNumber);
#endif
}

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

/* For testing...
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
