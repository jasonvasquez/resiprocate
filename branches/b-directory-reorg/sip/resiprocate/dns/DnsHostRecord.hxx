#ifndef RESIP_DNS_HOST_RECORD
#define RESIP_DNS_HOST_RECORD

#include "resiprocate/os/Data.hxx"
#include "resiprocate/os/Socket.hxx"
#include "resiprocate/dns/DnsResourceRecord.hxx"


namespace resip
{

class DnsResourceRecord;
class RROverlay;

class DnsHostRecord : public DnsResourceRecord
{
   public:
      DnsHostRecord(const RROverlay&);
      ~DnsHostRecord() {}

      // accessors.
      Data host() const;
      in_addr addr() const { return mAddr; }
      const Data& name() const { return mName; }
      bool isSameValue(const Data& value) const;
      
   private:
      in_addr mAddr;
      Data mName;
};

}


#endif
