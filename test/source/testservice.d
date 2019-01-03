module testservice;

import grpc;
import clientv3;

import hunt.logging;
import hunt.util.serialize;
import core.thread;
import core.time;
import hunt.util.serialize;

void testService(Channel channel)
{
    auto service = new Service(channel);
    testNormal(service , channel);
    logInfo("test ok");
}




void testNormal(Service service , Channel channel)
{
    enum SERVICE = "test";
    enum ADDR1 = "1.1.1.1:1001";
    enum ADDR2 = "1.1.1.2:1001";
    enum ADDR3 = "1.1.1.3:1001";
    long ID;
    Service.Meta[] list;

    ///watch
    int cnt = 0;
    WatchImpl watch = new WatchImpl(channel);
    auto watcher = watch.createWatcher((WatchImpl.NotifyItem item){
        logError(item.key , " " , item.op);
        switch(cnt){
            case 0:
                assert(item.key == SERVICE ~ "/" ~ ADDR1);
                break;
            case 1:
                assert(item.key == SERVICE ~ "/" ~ ADDR2);
                break;
            case 2:
                assert(item.key == SERVICE ~ "/" ~ ADDR3);
                break;
            case 3:
                assert(item.key == SERVICE ~ "/" ~ ADDR1 && item.op == Type.DELETE);
                break;
            case 4:
                assert(item.key == SERVICE ~ "/" ~ ADDR2 && item.op == Type.DELETE);
                break;
            default:
                assert(0);
        }
        cnt++;
    });

    watcher.watch(SERVICE , ID);

    service.registerInstance(SERVICE , ADDR1 );
    service.registerInstance(SERVICE , ADDR2 );
    service.registerInstance(SERVICE , ADDR3 );
    list = service.getAllInstances(SERVICE);
    assert(list.length == 3 && list[0].addr == ADDR1 && list[1].addr == ADDR2 && list[2].addr == ADDR3 );
    service.deregisterInstance(SERVICE , ADDR1);
    list = service.getAllInstances(SERVICE);
    assert(list.length == 2 && list[0].addr == ADDR2 && list[1].addr == ADDR3 );
    service.deregisterInstance(SERVICE , ADDR2);

    watcher.cancel(ID);

    service.deregisterInstance(SERVICE , ADDR3);
    list = service.getAllInstances(SERVICE);
    assert(list.length == 0);
    Thread.sleep(dur!"seconds"(1));
    assert(cnt == 5);
}
