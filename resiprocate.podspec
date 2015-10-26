# Note to self:
#  Current implementation requires these homebrew packages to be
#  installed so that the resiprocate configure script can be generated:
#
#   - autoconf
#   - automake
#   - libtool
#   - pkg-config


Pod::Spec.new do |s|
  s.name             = "resiprocate"
  s.version          = "1.10.0"
  s.summary          = "C++ implementation of SIP, ICE, TURN and related protocols."

  s.description      = <<-DESC
    This pod builds the client-side useful pieces of the resiprocate suite
    (rutil, resip, reTurn, etc.), but not the standalone client or server applications,
    such as repro.
                       DESC

  s.homepage         = "https://github.com/resiprocate/resiprocate"
  s.license          = { :type => 'BSD' }
  s.author           = { "Jason Vasquez" => "jason@mugfu.com" }
  s.source           = { :git => "https://github.com/resiprocate/resiprocate.git", :tag => "resiprocate-#{s.version.to_s}" }

  s.platform         = :ios, '7.0'
  s.requires_arc     = false

  s.dependency 'OpenSSL-Universal', '1.0.1.p'

  build_vars = <<-EOF
    DEVELOPER=`xcode-select -print-path`
    SDKVERSION=`xcrun --sdk iphoneos --show-sdk-version 2> /dev/null`
    SDKPATH="${DEVELOPER}/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator${SDKVERSION}.sdk"
    MIN_IOS_VERSION="7.0"
    export CFLAGS="-isysroot ${SDKPATH} -miphoneos-version-min=${MIN_IOS_VERSION} -arch i386 -arch x86_64"
  EOF

  s.prepare_command = <<-CMD
    # Run configure, primarily to generate config.h, a lower impedence way to
    # ensure we have the right definitions selected
    if [ ! -f config.h ]; then

      if [ ! -f configure ]; then
        autoreconf --install
      fi

      #{build_vars}
      ./configure --with-ssl
    fi

    # currently, xcodeproj does not correctly interpret .hxx files as headers.  Rename them. :(
    ls rutil/*.hpp >/dev/null || {
      export LC_ALL=C
      find . -name "*.[hc]xx" -print0 | xargs -0 sed -i '' -e 's/hxx/hpp/g'
      for i in $(find . -name "*.[hc]xx"); do
        NEW_NAME=$(echo $i | sed 's/\\(.\\)xx\$/\\1pp/')
        mv $i $NEW_NAME
      done
    }

    # configure srtp
    # if [ ! -f contrib/srtp/config.status ]; then
    #   cd contrib/srtp
    #   #{build_vars}
    #   ./configure
    #   cd ../..
    # fi

    # prepare boost
    # env > /tmp/debug.txt
    # if [ ! -d "contrib/boost" ]; then
    #   curl -sL https://s3.amazonaws.com/downloads.developertown.com/boost/boost_1_59_0.tar.gz | tar xzf - -C contrib
    #   mv contrib/boost_1_59_0 contrib/boost
    # fi
  CMD

  s.compiler_flags = [
    '-DHAVE_DLFCN_H',
    '-DHAVE_INTTYPES_H',
    '-DHAVE_MEMORY_H',
    '-DHAVE_STDINT_H',
    '-DHAVE_STDLIB_H',
    '-DHAVE_STRINGS_H',
    '-DHAVE_STRING_H',
    '-DHAVE_SYS_STAT_H',
    '-DHAVE_SYS_TIME_H',
    '-DHAVE_SYS_TYPES_H',
    '-DHAVE_TIME_H',
    '-DHAVE_UNISTD_H',
    '-DHAVE_sockaddr_in_len',
    '-DSTDC_HEADERS',
    '-DTIME_WITH_SYS_TIME',
    '-DUSE_SSL',
    '-DUSE_ARES',
    '-DTARGET_OS_IPHONE'
   ]


  s.prefix_header_contents = <<-EOF
    #define RESIP_SIP_MSG_MAX_BYTES 10485760

    /* Define WORDS_BIGENDIAN to 1 if your processor stores words with the most
       significant byte first (like Motorola and SPARC, unlike Intel). */
    #if defined AC_APPLE_UNIVERSAL_BUILD
    # if defined __BIG_ENDIAN__
    #  define WORDS_BIGENDIAN 1
    # endif
    #else
    # ifndef WORDS_BIGENDIAN
    /* #  undef WORDS_BIGENDIAN */
    # endif
    #endif
  EOF



  # s.source_files = [
  #                     'config.h'
  #                  ]
  # s.private_header_files = 'config.h'

  s.header_mappings_dir = '.'

  s.subspec 'contrib' do |ss|
    ss.subspec 'asio' do |sss|
      sss.source_files = [
        'contrib/asio/**/*.{h,i}pp'
      ]

      sss.public_header_files = [
        'contrib/asio/**/*.hpp'
      ]

      sss.header_mappings_dir = 'contrib/asio'
    end

    # ss.subspec 'srtp' do |sss|
    #   sss.source_files = [
    #     'contrib/srtp/srtp/*.c',
    #     'contrib/srtp/tables/*.c',
    #     'contrib/srtp/include/*.h',
    #     'contrib/srtp/crypto/**/*.{h,c}'
    #   ]
    #   sss.exclude_files = [
    #     'contrib/srtp/crypto/test/*.c',
    #     'contrib/srtp/crypto/rng/rand_linux_kernel.c'
    #   ]
    #   sss.public_header_files = [
    #     'contrib/srtp/include/*.h'
    #   ]
    #   sss.private_header_files = [
    #     'contrib/srtp/include/*_priv.h',
    #     'contrib/srtp/crypto/include/*.h'
    #   ]
    #   sss.header_dir = '.'
    #   sss.header_mappings_dir = '.'
    #   # sss.xcconfig = { 'HEADER_SEARCH_PATHS' => "$(SRCROOT)/Pods/Headers/blahabllah" }
    # end


    # ss.subspec 'boost' do |sss|
    #   sss.public_header_files = [
    #     'contrib/boost/**/*.{hpp,ipp,h}'
    #   ]

    #   sss.header_dir = 'boost'
    #   sss.header_mappings_dir = 'contrib/boost/boost'
    # end

  end

  s.subspec 'resip' do |ss|
    ss.dependency 'resiprocate/rutil'

    ss.subspec 'stack' do |sss|
      sss.source_files = [
        'resip/stack/*.{h,c}pp',
        'resip/stack/gen/*.cpp',
        'resip/stack/ssl/*.{h,c}pp',
      ]
      sss.exclude_files = [
        'resip/stack/ssl/MacSecurity*.{h,c}pp',
        'resip/stack/ssl/WinSecurity*.{h,c}pp'
      ]
    end
    ss.subspec 'dum' do |sss|
      sss.dependency 'resiprocate/resip/stack'
      sss.source_files = [
        'resip/dum/*.{h,c}pp',
        'resip/dum/ssl/*.{h,c}pp'
      ]
    end
  end

  s.subspec 'reflow' do |ss|
    ss.dependency 'resiprocate/rutil'
    ss.dependency 'resiprocate/reTurn'
    ss.dependency 'libsrtp'
    # ss.dependency 'resiprocate/contrib/srtp'

    ss.source_files = [
      'reflow/*.{h,c}pp',
      'reflow/dtls_wrapper/*.{h,c,hpp,cpp}'
    ]
  end

  s.subspec 'reTurn' do |ss|
    ss.dependency 'resiprocate/rutil'
    ss.dependency 'resiprocate/contrib/asio'
    # ss.dependency 'resiprocate/contrib/boost'

    ss.source_files = [
      'reTurn/*.{hpp,cpp}',
      'reTurn/client/*.{hpp,cpp}'
    ]

    ss.public_header_files = [
      'reTurn/*.{h,hpp}',
      'reTurn/client/*.{h,hpp}'
    ]
  end

  s.subspec 'rutil' do |ss|
    ss.source_files = [
      'rutil/*.{h,c,hpp,cpp}',
      'rutil/dns/*.{hpp,cpp}',
      'rutil/ssl/*.{hpp,cpp}',
      'rutil/stun/*.{hpp,cpp}',
      'rutil/dns/ares/*.{c,h}'
    ]

    ss.public_header_files = [
      'rutil/*.{h,hpp}',
      'rutil/dns/*.hpp',
      'rutil/ssl/*.hpp',
      'rutil/stun/*.hpp',
      'rutil/dns/ares/*.h'
    ]

    ss.private_header_files = 'rutil/dns/ares/ares_private.h'

    ss.exclude_files = [
      'rutil/WinCompat.cpp',
      'rutil/AndroidLogger.{hpp,cpp}'
    ]
  end

end
