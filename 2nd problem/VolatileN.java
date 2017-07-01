import java.util.ArrayList;
import java.util.Scanner;

public class VolatileN {

    volatile private static int condition = 1;

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
                    while (true){
                        if (i > 1) {
                            if (condition == i - 1) {
                                System.out.println("condition " + i);
                                condition = i;
                                break;
                            }
                        } else {
                            if (condition == N) {
                                System.out.println("condition " + i);
                                condition = i;
                                break;
                            }
                        }
                    }
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
