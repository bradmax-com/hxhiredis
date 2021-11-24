package;

import cpp.ConstPointer;
import cpp.StdString;
import cpp.Char;
import cpp.ConstCharStar;
import cpp.Pointer;

@:buildXml('
<!--<set name="root" value="../" />-->
<set name="root" value="${haxelib:hxhiredis}/" />
<files id="haxe">
    <compilerflag value="-I${root}/cpp/"/>
</files>
<target id="haxe">
    <flag value="-I${root}hiredis" />
    <flag value="-L${root}hiredis/" />
    <lib name="-lhiredis"/>
</target>
')

@:unreflective
@:structAccess
@:native("redisReply")
extern class RedisReply {}

@:unreflective
@:structAccess
@:native("redisReplyPtr")
extern class RedisReplyPtr {}

@:unreflective
@:structAccess
@:native("redisReplyPtrPtr")
extern class RedisReplyPtrPtr {}

@:unreflective
@:structAccess
@:native("redisContext")
extern class RedisContext {}

@:unreflective
@:structAccess
@:native("redisReader")
extern class RedisReader {}

@:unreflective
@:structAccess
@:native("HXredisReplyArray")
extern class HXredisReplyArrayAccess {}

@:unreflective
@:structAccess
@:native("HXredisReply")
extern class HXredisReply {
    public var error:Bool;
    public var type:Int;
    public var integer:Int;
    public var dval:Float;
    public var len:Int;
    public var str:String;
    public var vtype:String;
    public var elements:Int;
    public var element:HXredisReplyArrayAccess;
}

@:headerCode('
#include <../../cpp/HxRedisImport.h>

typedef struct HXredisReply HXredisReply;
    struct HXredisReply {
        bool error;
        int type;
        int integer;
        Float dval;
        int len;
        String str;
        String vtype;
        int elements;
        struct HXredisReply **element;
    };
')

@:headerInclude('../../cpp/HxRedisImport.h')
@:cppInclude('../../cpp/HxRedisGlue.cpp')

class Redis {
    public static inline var HX_REDIS_ERR = -1;
    public static inline var HX_REDIS_OK = 0;

    public static inline var HX_REDIS_ERR_IO = 1; /* Error in read or write */
    public static inline var HX_REDIS_ERR_EOF = 3; /* End of file */
    public static inline var HX_REDIS_ERR_PROTOCOL = 4; /* Protocol error */
    public static inline var HX_REDIS_ERR_OOM = 5; /* Out of memory */
    public static inline var HX_REDIS_ERR_TIMEOUT = 6; /* Timed out */
    public static inline var HX_REDIS_ERR_OTHER = 2; /* Everything else... */

    public static inline var HX_REDIS_REPLY_STRING = 1;
    public static inline var HX_REDIS_REPLY_ARRAY = 2;
    public static inline var HX_REDIS_REPLY_INTEGER = 3;
    public static inline var HX_REDIS_REPLY_NIL = 4;
    public static inline var HX_REDIS_REPLY_STATUS = 5;
    public static inline var HX_REDIS_REPLY_ERROR = 6;
    public static inline var HX_REDIS_REPLY_DOUBLE = 7;
    public static inline var HX_REDIS_REPLY_BOOL = 8;
    public static inline var HX_REDIS_REPLY_MAP = 9;
    public static inline var HX_REDIS_REPLY_SET = 10;
    public static inline var HX_REDIS_REPLY_ATTR = 11;
    public static inline var HX_REDIS_REPLY_PUSH = 12;
    public static inline var HX_REDIS_REPLY_BIGNUM = 13;
    public static inline var HX_REDIS_REPLY_VERB = 14;

    var context:Pointer<RedisContext>;
    var reader:Pointer<RedisReader>;
    var reply:RedisReplyPtr;
    var bulkSize = 0;

    public function new(){
    }
    
    public function connect(host:String, port:Int):Void{
        context = __redisConnect(StdString.ofString(host).c_str(), port);
        try{
            checkError();
        }catch(err:Dynamic){
            throw err;
        }
    }

    public function reconnect():Void{
        var i = __redisReconnect(context);

        if(i == 0) return;
        try{
            checkError();
        }catch(err:Dynamic){
            throw err;
        }
    }

    public function command(cmd:String):Dynamic{
        var resPointer = __command(context, cmd);
        var res = resPointer.ref;
        trace("ERROR: "+res.error);

        if(res.error){
            throw res.str;
        }

        var retValue:Dynamic = readReplyObject(res);

        try{
            checkError();
        }catch(err:Dynamic){
            throw err;
        }

        untyped __cpp__("__freeHXredisReply({0})", resPointer);
        return retValue;

        // var c = __command(context, cmd);
        // try{
        //     checkError();
        // }catch(err:Dynamic){
        //     throw err;
        // }
        // return c;
    }

    public function appendCommand(cmd:String){
        bulkSize++;
        __redisAppendCommand(context, StdString.ofString(cmd).c_str());
        try{
            checkError();
        }catch(err:Dynamic){
            throw err;
        }
    }

    public function getBulkReply():Array<String>{
        var arr = new Array<String>();

        while(bulkSize-- > 0){
            var rep:Dynamic = cast getReply();
            if(rep != null)
                arr.push(rep);
        }
        bulkSize = 0;
        return arr;
    }

    function checkError(){
        var s:String = __checkError(context);

        if(s != ""){
            bulkSize = 0;
            throw s;
        }
    }

    function getReply():Dynamic{
        var resPointer = __getReply(context);
        var res = resPointer.ref;

        if(res.error){
            throw res.str;
        }

        var retValue:Dynamic = readReplyObject(res);

        try{
            checkError();
        }catch(err:Dynamic){
            throw err;
        }

        untyped __cpp__("__freeHXredisReply({0})", resPointer);
        return retValue;
    }

    function readReplyObject(res:HXredisReply):Dynamic{
        trace("redis", res.type, res.str, res.integer, res.dval);
        switch(res.type){
            case HX_REDIS_REPLY_STRING:
                return res.str;
            case HX_REDIS_REPLY_INTEGER:
                return res.integer;
            case HX_REDIS_REPLY_DOUBLE:
                return res.dval;
            case HX_REDIS_REPLY_BOOL:
                return res.integer == 1;
            case HX_REDIS_REPLY_ARRAY:
                var arr:Array<Dynamic> = [];
                for(i in 0...res.elements){
                    var type:Int = untyped __cpp__("{0}.element[{1}]->type",res,i);
                    switch(type){
                        case HX_REDIS_REPLY_STRING:
                            var val:String = untyped __cpp__("{0}.element[{1}]->str",res,i);
                            arr.push(val);
                        case HX_REDIS_REPLY_INTEGER:
                            var val:Int = untyped __cpp__("{0}.element[{1}]->integer",res,i);
                            arr.push(val);
                        case HX_REDIS_REPLY_DOUBLE:
                            var val:Float = untyped __cpp__("{0}.element[{1}]->dval",res,i);
                            arr.push(val);
                        case HX_REDIS_REPLY_BOOL:
                            var val:Int = untyped __cpp__("{0}.element[{1}]->integer",res,i);
                            arr.push(val == 1);
                    }
                }
                return arr;
        }
        return null;
    }

    function freeReply(){
        __freeReplyObject(reply);
    }

    function readerCreate(){
        reader = __redisReaderCreate();
    }

    function readerFree(){
        __redisReaderFree(reader);
    }

    function readerFeed(){
        var size = 1024;
        var buffer:ConstCharStar = null;
        __redisReaderFeed(reader, buffer, size);
        return buffer.toString();
    }

    @:extern
    @:native("redisReaderCreate")
    public static function __redisReaderCreate():Pointer<RedisReader>;

    @:extern
    @:native("redisReaderFree")
    public static function __redisReaderFree(reader:Pointer<RedisReader>):Void;

    @:extern
    @:native("redisReaderFeed")
    public static function __redisReaderFeed(reader:Pointer<RedisReader>, buffer:ConstCharStar, size:Int):Void;

    @:extern
    @:native("__getReply")
    public static function __getReply(c:Pointer<RedisContext>):Pointer<HXredisReply>;

    @:extern
    @:native("__command")
    public static function __command(c:Pointer<RedisContext>, cmd:String):Pointer<HXredisReply>;

    @:extern
    @:native("__checkError")
    public static function __checkError(c:Pointer<RedisContext>):String;

    @:extern
    @:native("freeReplyObject")
    public static function __freeReplyObject(reply:RedisReplyPtr):Void;

    @:extern
    @:native("redisAppendCommand")
    public static function __redisAppendCommand(context:Pointer<RedisContext>, command:ConstPointer<Char>):Int;

    @:extern
    @:native("redisConnect")
    public static function __redisConnect(host:ConstPointer<Char>, port:Int):Pointer<RedisContext>;

    @:extern
    @:native("redisReconnect")
    public static function __redisReconnect(c:Pointer<RedisContext>):Int;
}