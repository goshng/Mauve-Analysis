#ifndef __RNG_H__
#define __RNG_H__

#include <gsl/gsl_rng.h>
#include <time.h>

gsl_rng * rng;

void makerng() {
    const gsl_rng_type *rng_type;
    long int rng_seed;
    gsl_rng_env_setup();
    rng_type = gsl_rng_default;
    rng_seed = gsl_rng_default_seed;
    rng = gsl_rng_alloc (rng_type);
    unsigned int seed;
    FILE *devrandom;

 if ((devrandom = fopen("/dev/urandom","r")) == NULL) {
   seed = (unsigned long) time(NULL);
   printf("Got seed %u from time()\n",seed);
 } else {
   fread(&seed,sizeof(seed),1,devrandom);
   printf("Got seed %u from /dev/urandom\n",seed);
   fclose(devrandom);
 }
    //seed=0;//This is for debugging purposes only
    gsl_rng_set(rng,seed);
}


#endif // __RNG_H__
