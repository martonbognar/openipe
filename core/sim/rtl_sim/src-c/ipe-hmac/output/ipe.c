 __attribute__((section(".ipe_entry"))) int attest_internal(void)
{
  uint8_t key[64] = {0};
  for (int i = 0; i < 64; ++ i)
  {
    key[i] = persistent_key[i];
  }

  hmac((uint8_t *) key, (uint8_t *) key, (uint32_t) 64, (uint8_t *) mac_region, (uint32_t) 32);
  hmac((uint8_t *) mac_region, (uint8_t *) key, (uint32_t) 32, (uint8_t *) 0x1000, (uint32_t) 0x0800);
  return signal_done_stub(3);
}

