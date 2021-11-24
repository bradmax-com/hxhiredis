#include "./HxRedisImport.h"
#include <stdio.h>
#include <iostream>
#include <vector>

using namespace std;

String __checkError(redisContext *c){
    bool isNull = c == NULL;
    bool err = ((redisContext *)c)->err;
    String errstr = String::create(((redisContext *)c)->errstr, 128);
    if(isNull){
        return String("Can't allocate redis context");        
    }else if(err){
        return errstr;
    }else{
        return String("");
    }
}

HXredisReply *__command(redisContext *c, String cmd){
    void *res = redisCommand((redisContext *)c, cmd.__s);
    bool isNull = res == NULL;
    HXredisReply *rep = new HXredisReply();
    if(isNull){
        std::cout << "\nNULL\n";
        rep->error = true;
        rep->str = String::create("");
        return rep;
    }else{
        int type = ((redisReply *)res)->type;
        std::cout << "\ntype: " << type << "\n";
        if(type == 1){
            std::cout << "\n" << ((redisReply *)res)->len << ":" << ((redisReply *)res)->str << "\n";
        }
    }
    

    rep->error = false;
    rep->str = String::create(((redisReply *)res)->str);
    rep->type = ((redisReply *)res)->type;
    rep->integer = ((redisReply *)res)->integer;
    rep->dval = ((redisReply *)res)->dval;
    rep->len = ((redisReply *)res)->len;
    rep->vtype = ((redisReply *)res)->vtype;
    rep->elements = ((redisReply *)res)->elements;
    
    // String response = String::create(((redisReply *)res)->str);
    freeReplyObject(res);
    return rep;
}

void __freeHXredisReply(struct HXredisReply *rep){
    if(rep->elements > 0){        
        int i;
        for(i = 0 ; i < rep->elements ; i++){
            free(rep->element[i]);
        }
        free(rep->element);
    }
    free(rep);
}

HXredisReply *__getReply(redisContext *c){
    redisReply *res;
    int status = redisGetReply((redisContext *)c, (void **)&res);
    HXredisReply *rep = new HXredisReply();
    if(status == -1){
        rep->error = true;
        rep->str = String("Redis connection error");
        // freeReplyObject(res);
        return rep;
    }

    rep->error = false;
    rep->str = String::create(((redisReply *)res)->str);
    rep->type = ((redisReply *)res)->type;
    rep->integer = ((redisReply *)res)->integer;
    rep->dval = ((redisReply *)res)->dval;
    rep->len = ((redisReply *)res)->len;
    rep->vtype = ((redisReply *)res)->vtype;
    rep->elements = ((redisReply *)res)->elements;

    if(rep->elements > 0){
        rep->element = (struct HXredisReply **)calloc(rep->elements, sizeof(struct HXredisReply *));
        
        int i;
        for(i = 0 ; i < rep->elements ; i++){
            rep->element[i] = (struct HXredisReply *)malloc(sizeof(struct HXredisReply));
            rep->element[i]->error = false;
            rep->element[i]->str = String::create(res->element[i]->str);
            rep->element[i]->type = res->element[i]->type;
            rep->element[i]->integer = ((redisReply *)res)->element[i]->integer;
            rep->element[i]->dval = ((redisReply *)res)->element[i]->dval;
            rep->element[i]->len = ((redisReply *)res)->element[i]->len;
            rep->element[i]->vtype = ((redisReply *)res)->element[i]->vtype;
        }
    }
    
    freeReplyObject(res);
    return rep;
}