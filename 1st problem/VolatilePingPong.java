public class VolatilePingPong {

    volatile private static boolean pingFlag = true;

    private static Runnable createRunnable(final boolean pingOrPong) {
        return new Runnable() {
            @Override
            public void run() {
                int i = 0;
                while (i < 11) {
                        if (!(pingFlag^pingOrPong)) {
                            if (pingOrPong) {
                                System.out.println("Ping " + i);
                            } else {
                                System.out.println("Pong " + i);
                            }
                            pingFlag = !pingOrPong;
                            i++;
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
