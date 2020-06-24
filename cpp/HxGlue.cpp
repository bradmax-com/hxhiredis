#include "./Import.h"

String __checkError(redisContext *c){
    bool isNull = c == NULL;
    bool err = ((redisContext *)c)->err;
    String errstr = String::create("dupa");
    // String errstr = String::create(((redisContext *)c)->errstr, 16);
    if(isNull){
        return String("Can't allocate redis context");        
    }else if(err){
        return errstr;
    }else{
        return String("");
    }
}

String __command(redisContext *c, String cmd){
    void *res = redisCommand((redisContext *)c, cmd.__s);
    bool isNull = res == NULL;
    if(isNull)
        return String("");
    
    String response = String::create(((redisReply *)res)->str);
    freeReplyObject(res);
    return response;
}

HXredisReply __getReply(redisContext *c){
    redisReply *res;
    int status = redisGetReply((redisContext *)c, (void **)&res);
    HXredisReply rep;
    if(status == -1){
        rep.error = true;
        rep.str = String("Redis connection error");
        return rep;
    }

    rep.error = false;
    rep.str = String::create(((redisReply *)res)->str);
    rep.type = ((redisReply *)res)->type;
    rep.integer = ((redisReply *)res)->integer;
    rep.dval = ((redisReply *)res)->dval;
    rep.len = ((redisReply *)res)->len;
    
    return rep;
}