import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.ReentrantLock;

public class ConcurrentPingPong {

    private static boolean flag = true;
    private static ReentrantLock shared = new ReentrantLock();
    private static Condition condition = shared.newCondition();

    private static Runnable createRunnable(final boolean pingOrPong) {
        return new Runnable() {
            @Override
            public void run() {
                int i = 0;
                while (i < 11) {
                    shared.lock();
                    try {
                        if (!(flag ^ pingOrPong)) {
                            if (pingOrPong) {
                                System.out.println("Ping " + i);
                            } else {
                                System.out.println("Pong " + i);
                            }
                            flag = !pingOrPong;
                            condition.signalAll();
                            i++;
                        } else {
                            try {
                                while ((flag ^ pingOrPong)) {
                                    condition.await();
                                }
                            } catch (InterruptedException e) {
                                e.printStackTrace();
                            }
                        }
                    } finally {
                        shared.unlock();
                    }
                }
            }
        };
    }

    public static void main(String args[]) {
        new Thread(createRunnable(true)).start();
        new Thread(createRunnable(false)).start();
    }
}
