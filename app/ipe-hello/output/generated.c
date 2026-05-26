 __attribute__((section(".ipe_entry"))) int ipe_func_internal(int a)
{
  char *c = (char *) ipe_dummy1;
  * c = 0;
  return (a + b) + ipe_dummy2_outside_stub(2);
}

