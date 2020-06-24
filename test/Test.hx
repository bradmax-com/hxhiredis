package;

class Test{

    public static function main(){
        var n = new Redis();
        n.test();
    }

    public function test(){
        var connected = false;
        try{
            connect("127.0.0.1", 6379);
            connected = true;
        }catch(err:Dynamic){
            trace(err);
            connected = false;
        }

        while(true){
            try{
                if(connected){
                    testBulk();
                    Sys.sleep(1);
                }else{
                    Sys.sleep(1);
                    reconnect();
                    connected = true;
                }
            }catch(err:Dynamic){
                connected = false;
                trace(err);
            }
        }
    }

    function testBulk(){
        appendCommand('SET A a');
        appendCommand('SET B 1');
        appendCommand('SET C 1.1');
        appendCommand('SET D true');
        appendCommand('INCR B');
        trace(getBulkReply());
        appendCommand('GET A');
        appendCommand('GET B');
        appendCommand('GET C');
        appendCommand('GET D');
        trace(getBulkReply());
    }
}