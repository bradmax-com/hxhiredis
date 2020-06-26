package;

class Test{

    public static function main(){
        new Test();
    }

    var r = new Redis();

    public function new(){
        test();
    }

    public function test(){
        r = new Redis();
        var connected = false;
        try{
            r.connect("bradmax-redis.kelmfo.clustercfg.euc1.cache.amazonaws.com", 6379);
            // r.connect("172.31.7.94", 6379);
            // r.connect("127.0.0.1", 6379);
            connected = true;
        }catch(err:Dynamic){
            trace(err);
            connected = false;
        }

        while(true){
            try{
                if(connected){
                    testBulk();
                    // Sys.sleep(1);
                }else{
                    Sys.sleep(1);
                    r.reconnect();
                    connected = true;
                }
            }catch(err:Dynamic){
                connected = false;
                trace(err);
            }
        }
    }

    function testBulk(){
        for(i in 0...100000){
            r.appendCommand('SADD bigset $i');
        }
        r.appendCommand('SET A a');
        r.appendCommand('SET B 1');
        r.appendCommand('SET C 1.1');
        r.appendCommand('SET D true');
        r.appendCommand('INCR B');
        r.appendCommand('GET A');
        r.appendCommand('GET B');
        r.appendCommand('GET C');
        r.appendCommand('GET D');
        r.appendCommand("SADD setx 2");
        r.appendCommand("SADD setx 3");
        r.appendCommand("SADD setx dupa");
        r.appendCommand("SCARD setx");
        r.appendCommand("SMEMBERS setx");
        r.appendCommand("SCARD bigset");
        trace(r.getBulkReply());
    }
}