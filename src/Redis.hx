package;

import cpp.ConstPointer;
import cpp.StdString;
import cpp.Char;
import cpp.Star;
import cpp.ConstStar;
import cpp.CastCharStar;
import cpp.ConstCharStar;
import cpp.RawConstPointer;
import cpp.RawPointer;
import cpp.Pointer;
import cpp.NativeString;


@:buildXml('
<set name="root" value="../" />
<files id="haxe">
    <compilerflag value="-I${root}/cpp/"/>
</files>

<files id="__main__">
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
    public var element:HXredisReply;
}

@:headerCode('
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
        Dynamic element;
    };
')



@:headerInclude('./../cpp/Import.h')
@:cppInclude('./../cpp/HxGlue.cpp')

// typedef HxReply = {
//     type:Int,
//     integer:Int, /* The integer when type is REDIS_REPLY_INTEGER */
//     dval:Float, /* The double when type is REDIS_REPLY_DOUBLE */
//     len:Int, /* Length of string */
//     str:String, /* Used for REDIS_REPLY_ERROR, REDIS_REPLY_STRING
//                   REDIS_REPLY_VERB, and REDIS_REPLY_DOUBLE (in additional to dval). */
//     vtype:String, /* Used for REDIS_REPLY_VERB, contains the null
//                       terminated 3 character content type, such as "txt". */
//     elements:Int, /* number of elements, for REDIS_REPLY_ARRAY */
//     element:Array<Dynamic> /* elements vector for REDIS_REPLY_ARRAY */
// }



class Redis {
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
        trace(i);
        if(i == 0)
            return;

        try{
            checkError();
        }catch(err:Dynamic){
            throw err;
        }
    }

    public function command(cmd:String):Dynamic{
        var c = __command(context, cmd);
        try{
            checkError();
        }catch(err:Dynamic){
            throw err;
        }
        return c;
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
        while(bulkSize-- > 0)
            arr.push(cast getReply());


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
        var res = __getReply(context);
        if(res.error){
            throw res.str;
        }
        try{
            checkError();
        }catch(err:Dynamic){
            throw err;
        }
        return res.str;
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
    public static function __getReply(c:Pointer<RedisContext>):HXredisReply return null;

    @:extern
    @:native("__command")
    public static function __command(c:Pointer<RedisContext>, cmd:String):String return null;

    @:extern
    @:native("__checkError")
    public static function __checkError(c:Pointer<RedisContext>):String return null;

    @:extern
    @:native("freeReplyObject")
    public static function __freeReplyObject(reply:RedisReplyPtr):Void;

    @:extern
    @:native("redisAppendCommand")
    public static function __redisAppendCommand(context:Pointer<RedisContext>, command:ConstPointer<Char>):Int;

    @:extern
    @:native("redisConnect")
    public static function __redisConnect(host:ConstPointer<Char>, port:Int):Pointer<RedisContext> return null;

    @:extern
    @:native("redisReconnect")
    public static function __redisReconnect(c:Pointer<RedisContext>):Int return null;

}