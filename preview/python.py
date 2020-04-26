import functools
import signal


class Timeout:
  """Timeout class using ALARM signal."""

  class Timeout(Exception):
    pass

  def __init__(self, sec):
    self.sec = sec

  def __enter__(self):
    signal.signal(signal.SIGALRM, self.raise_timeout)
    signal.alarm(self.sec)

  def __exit__(self, *args):
    signal.alarm(0)  # disable alarm

  def raise_timeout(self, *args):
    raise Timeout.Timeout()

  @property
  def waiting_sec(self):
    return self.sec


def timeout(sec):
  def decorator(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
      with Timeout(sec):
        func(*args, **kwargs)
    return wrapper
  return decorator


import subprocess


@timeout(3)
def main():
  # TODO (thuyen): Do something
  subprocess.run(['sh', 'run.sh'], check=True)


if __name__ == "__main__":
  main()
