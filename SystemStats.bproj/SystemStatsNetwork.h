#if defined(__APPLE__)
#include <sys/types.h>
#include <net/if.h>
#include <net/route.h>
#include <string.h>

/* Routing snapshots mix interface, address and multicast records. Only their
   four-byte prefix is shared; address records can be shorter than if_msghdr. */
static void SystemStatsNetworkCounters(const void *bytes, size_t length,
                                      unsigned long long *rx, unsigned long long *tx)
{
  const unsigned char *cursor = bytes;
  struct {
    unsigned short length;
    unsigned char version;
    unsigned char type;
  } header;

  *rx = *tx = 0;
  while(length >= sizeof(header))
    {
      memcpy(&header, cursor, sizeof(header));
      if(header.length < sizeof(header) || header.length > length)
        break;
      if(header.version == RTM_VERSION && header.type == RTM_IFINFO2 &&
         header.length >= sizeof(struct if_msghdr2))
        {
          struct if_msghdr2 info;
          memcpy(&info, cursor, sizeof(info));
          if(!(info.ifm_flags & IFF_LOOPBACK))
            {
              *rx += info.ifm_data.ifi_ibytes;
              *tx += info.ifm_data.ifi_obytes;
            }
        }
      cursor += header.length;
      length -= header.length;
    }
}
#endif
