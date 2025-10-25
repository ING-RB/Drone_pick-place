/*  Copyright 2018-2021 The MathWorks, Inc. */

#ifndef _TMW_THREADS_H
#define _TMW_THREADS_H

#include <features.h>

__BEGIN_DECLS

/***********/
/* Threads */
/***********/

typedef struct __pthread *thrd_t;
typedef int (*thrd_start_t)(void *);

int thrd_create(thrd_t *thr, thrd_start_t func, void *arg);
int thrd_equal(thrd_t lhs, thrd_t rhs);
thrd_t thrd_current(void);
int thrd_sleep(const struct timespec* time_point, struct timespec* remaining);
void thrd_yield(void);
_Noreturn void thrd_exit(int res);
int thrd_detach(thrd_t thr);
int thrd_join(thrd_t thr, int *res);

enum {
        thrd_success,
        thrd_timedout,
        thrd_busy,
        thrd_nomem,
        thrd_error
};


/********************/
/* Mutual exclusion */
/********************/

typedef struct { volatile int __mtx[10]; } mtx_t;

int mtx_init(mtx_t* mutex, int type);
int mtx_lock(mtx_t* mutex);
int mtx_timedlock(mtx_t *restrict mutex, const struct timespec *restrict time_point);
int mtx_trylock(mtx_t *mutex);
int mtx_unlock(mtx_t *mutex);
void mtx_destroy(mtx_t *mutex);

enum {
        mtx_plain,
        mtx_recursive,
        mtx_timed
};

typedef int once_flag;
#define ONCE_FLAG_INIT 0
void call_once(once_flag* flag, void (*func)(void));


/***********************/
/* Condition variables */
/***********************/

typedef struct { volatile int __cnd[10]; } cnd_t;

int cnd_init(cnd_t* cond);
int cnd_signal(cnd_t *cond);
int cnd_broadcast(cnd_t *cond);
int cnd_wait(cnd_t* cond, mtx_t* mutex);
int cnd_timedwait(cnd_t* restrict cond, mtx_t* restrict mutex, const struct timespec* restrict time_point);
void cnd_destroy(cnd_t* cond);

/************************/
/* Thread-local storage */
/************************/

#define thread_local _Thread_local

typedef unsigned tss_t;

#define TSS_DTOR_ITERATIONS 6

typedef void (*tss_dtor_t)(void *);

int tss_create(tss_t* tss_key, tss_dtor_t destructor);
void *tss_get(tss_t tss_key);
int tss_set(tss_t tss_id, void *val);
void tss_delete(tss_t tss_id);

__END_DECLS

#endif /* _TMW_THREADS_H */
