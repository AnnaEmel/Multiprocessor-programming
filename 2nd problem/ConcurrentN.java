import java.util.ArrayList;
import java.util.Scanner;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.ReentrantLock;

/**
 * Created by Anna on 28.10.2016.
 */
public class ConcurrentN {
    private static int status = 1;
    private static ReentrantLock shared = new ReentrantLock();
    private static Condition condition = shared.newCondition();

    private static Runnable createRunnable(final int i, int N, int M) {
        return new Runnable() {
            @Override
            public void run() {
                int k = M / N;
                int r = M % N;
                int n = k;
                if (i <= r + 1 && i != 1) {
                    n += 1;
                }
                for (int j = 1; j <= n; j++) {
                    shared.lock();
                    if (i > 1) {
                        while (status != i - 1) {
                            try {
                                condition.await();
                            } catch (InterruptedException e) {
                                e.printStackTrace();
                            }
                        }
                        System.out.println("condition " + i);
                        status = i;
                        condition.signalAll();
                    } else {
                        while (status != N) {
                            try {
                                condition.await();
                            } catch (InterruptedException e) {
                                e.printStackTrace();
                            }
                        }
                        System.out.println("condition " + i);
                        status = i;
                        condition.signalAll();
                    }
                    shared.unlock();
                }
            }
        };
    }


    public static void main(String args[]) {
        Scanner in = new Scanner(System.in);
        int N = in.nextInt();
        int M = in.nextInt();
        System.out.println("N =" + N);
        System.out.println("M =" + M);

        ArrayList<Thread> threads = new ArrayList<>();


        for (int i = 1; i <= N; i++) {
            Thread thread = new Thread(createRunnable(i, N, M));
            threads.add(thread);
            thread.start();
        }

        for (Thread thread : threads) {
            try {
                thread.join();
            } catch (InterruptedException e) {
                System.err.println("Exception caught during join()");
            }
        }
    }
}