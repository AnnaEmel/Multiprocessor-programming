public class SynchronizedPingPong {

    final static private Object shared = new Object();
    private static boolean flag = true;

    private static Runnable createRunnable(final boolean pingOrPong) {
        return new Runnable() {
            @Override
            public void run() {
                int i = 0;
                while (i < 11) {
                    synchronized (shared) {
                        if (!(flag ^ pingOrPong)) {
                            if (pingOrPong) {
                                System.out.println("Ping " + i);
                            } else {
                                System.out.println("Pong " + i);
                            }
                            flag = !pingOrPong;
                            shared.notifyAll();
                            i++;
                        } else {
                            try {
                                while ((flag ^ pingOrPong)) {
                                    shared.wait();
                                }
                            } catch (InterruptedException e) {
                                e.printStackTrace();
                            }
                        }
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
