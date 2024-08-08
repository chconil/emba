# Copyright (c) 2015 - 2016, Daming Dominic Chen
# Copyright (c) 2017 - 2020, Mingeun Kim, Dongkwan Kim, Eunsoo Kim
# Copyright (c) 2022 - 2024 Siemens Energy AG
#
# This script is based on the original scripts from the firmadyne and firmAE project
# Original firmadyne project can be found here: https://github.com/firmadyne/firmadyne
# Original firmAE project can be found here: https://github.com/pr0v3rbs/FirmAE

# shellcheck disable=SC2148
BUSYBOX="/busybox"

ORANGE="\033[0;33m"
NC="\033[0m"

# This script is based on the original FirmAE inferFile.sh script 
# This script supports multiple startup services, colored output
# and more services

"${BUSYBOX}" echo "[*] EMBA inferService script starting ..."

"${BUSYBOX}" echo "[*] Service detection running ..."

# The manual starter can be used to write startup scripts manually and help
# EMBA getting into the right direction
# This script must be placed directly into the filesystem as /etc/manual.starter
if [ -e /etc/manual.starter ]; then
  if ! "${BUSYBOX}" grep -q "/etc/manual.starter" /firmadyne/service 2>/dev/null; then
    "${BUSYBOX}" echo -e "[*] Writing EMBA service for ${ORANGE}manual starter service${NC}"
    "${BUSYBOX}" echo -e -n "/etc/manual.starter\n" >> /firmadyne/service
  fi
fi

if [ -d /etc/init.d/ ]; then
  for SERVICE in $("${BUSYBOX}" find /etc/init.d/ -type f -name "*httpd*" -o -type f -name "ftpd" -o -type f -name "miniupnpd" \
    -o -type f -name "*apache*" -o -type f -name "*service*"); do
    # -o -type f -name "*apache*" -o -type f -name "*init*" -o -type f -name "*service*"); do
    if "${BUSYBOX}" echo "${SERVICE}" | grep -q "factory"; then
      # do not use entries like factory.init or init.factory and so on
      continue
    fi
    if [ -e "${SERVICE}" ]; then
      if ! "${BUSYBOX}" grep -q "${SERVICE}" /firmadyne/service 2>/dev/null; then
        "${BUSYBOX}" echo -e "[*] Writing EMBA service for ${ORANGE}${SERVICE} service${NC}"
        "${BUSYBOX}" echo -e -n "${SERVICE} start\n" >> /firmadyne/service
      fi
    fi
  done
fi

if [ -d /etc/rc.d/ ]; then
  for SERVICE in $("${BUSYBOX}" find /etc/rc.d/ -name "S*httpd*" -o -name "S*apache*"); do
    if [ -e "${SERVICE}" ]; then
      if ! "${BUSYBOX}" grep -q "${SERVICE}" /firmadyne/service 2>/dev/null; then
        "${BUSYBOX}" echo -e "[*] Writing EMBA service for ${ORANGE}${SERVICE} service${NC}"
        "${BUSYBOX}" echo -e -n "${SERVICE} start\n" >> /firmadyne/service
      fi
    fi
  done
fi

if [ -e /bin/boa ]; then
  if ! "${BUSYBOX}" grep -q boa /firmadyne/service 2>/dev/null; then
    "${BUSYBOX}" echo -e "[*] Writing EMBA service for ${ORANGE}/bin/boa${NC}"
    "${BUSYBOX}" echo -e -n "/bin/boa\n" >> /firmadyne/service
    for BOA_CONFIG in $("${BUSYBOX}" find / -name "*boa*.conf" -type f); do
      # extract the directory index from config and search for it in the filesystem - this is needed to start boa with the correct
      # web root directory
      # shellcheck disable=SC2016
      DIR_INDEX=$("${BUSYBOX}" grep "DirectoryIndex" "${BOA_CONFIG}" | "${BUSYBOX}" sed '/^\#/d' | "${BUSYBOX}" awk '{print $2}' | "${BUSYBOX}" head -1)
      for DIR_BOA_RFS in $("${BUSYBOX}" find / -name "${DIR_INDEX}" | "${BUSYBOX}" grep -v "${DIR_INDEX}_extract"); do
        # as we are looking for a file from DirectoryIndex we need to strip it to the directory
        DIR_INDEX_FS=$("${BUSYBOX}" dirname "${DIR_BOA_RFS}")
        # write the service starter with config file
        "${BUSYBOX}" echo -e "[*] Writing EMBA starter for ${ORANGE}/bin/boa - ${BOA_CONFIG} / ${DIR_INDEX_FS}${NC}"
        "${BUSYBOX}" echo -e -n "/bin/boa -p ${DIR_INDEX_FS} -f ${BOA_CONFIG}\n" >> /firmadyne/service
        # is -c a valid option?!?
        "${BUSYBOX}" echo -e -n "/bin/boa -p ${DIR_INDEX_FS} -c ${BOA_CONFIG}\n" >> /firmadyne/service
      done
    done
  fi
fi

# Some examples for testing:
# mini_httpd: F9K1119_WW_1.00.01.bin
# twonkystarter: F9K1119_WW_1.00.01.bin

for BINARY in $("${BUSYBOX}" find / -name "lighttpd" -type f -o -name "upnp" -type f -o -name "upnpd" -type f \
  -o -name "*telnetd" -type f -o -name "mini_httpd" -type f -o -name "miniupnpd" -type f -o -name "mini_upnpd" -type f \
  -o -name "twonkystarter" -type f -o -name "httpd" -type f -o -name "goahead" -type f -o -name "alphapd" -type f \
  -o -name "uhttpd" -type f -o -name "miniigd" -type f -o -name "ISS.exe" -type f -o -name "ubusd" -type f \
  -o -name "streamd" -type f -o -name "wscd" -type f -o -name "ftpd" -type f -o -name "11N_UDPserver" -type f \
  -o -name "pppoe-server" -type f -o -name "pppd" -type f -o -name "nvram_daemon" -type f); do

  if [ -x "${BINARY}" ]; then
    SERVICE_NAME=$("${BUSYBOX}" basename "${BINARY}")
    # entry for lighttpd:
    if [ "$("${BUSYBOX}" echo "${SERVICE_NAME}")" == "lighttpd" ]; then
      # check if this service is already in the service file:
      # if ! "${BUSYBOX}" grep -q "${SERVICE_NAME}" /firmadyne/service 2>/dev/null; then
        # check if we have a configuration available and iterate
        for LIGHT_CONFIG in $("${BUSYBOX}" find / -name "*lighttpd*.conf" -type f); do
          # write the service starter with config file
          "${BUSYBOX}" echo -e "[*] Writing EMBA starter for ${ORANGE}${BINARY} - ${LIGHT_CONFIG}${NC}"
          if "${BUSYBOX}" grep -q "ssl.pemfile" "${LIGHT_CONFIG}"; then
            # check if we have ssl enabled and the pem file is available
            # see also https://www.greynoise.io/blog/debugging-d-link-emulating-firmware-and-hacking-hardware
            PEM_FILE=$("${BUSYBOX}" grep "ssl.pemfile" "${LIGHT_CONFIG}" | "${BUSYBOX}" sort -u | "${BUSYBOX}" cut -d\" -f2)
            if ! [ -f "${PEM_FILE}" ]; then
              "${BUSYBOX}" echo -e "[*] Disabling ssl configuration for ${ORANGE}${BINARY} - ${LIGHT_CONFIG} -> ${LIGHT_CONFIG}_ssl_disable${NC}"
              sed 's/ssl\.engine = \"enable\"/ssl\.engine = \"disable\"/' "${LIGHT_CONFIG}" > "${LIGHT_CONFIG}_ssl_disable"
              "${BUSYBOX}" echo -e -n "${BINARY} -f ${LIGHT_CONFIG}_ssl_disable\n" >> /firmadyne/service
            fi
          fi
          "${BUSYBOX}" echo -e -n "${BINARY} -f ${LIGHT_CONFIG}\n" >> /firmadyne/service
          for LIGHT_LIBS in $("${BUSYBOX}" find / -type d -path "*lighttpd/lib*"); do
            # write the service starter with config file
            "${BUSYBOX}" echo -e "[*] Writing EMBA starter for ${ORANGE}${BINARY} - ${LIGHT_CONFIG} - ${LIGHT_LIBS}${NC}"
            "${BUSYBOX}" echo -e -n "${BINARY} -f ${LIGHT_CONFIG} -m ${LIGHT_LIBS}\n" >> /firmadyne/service
            if [ -f "${LIGHT_CONFIG}"_ssl_disable ]; then
              "${BUSYBOX}" echo -e "[*] Writing EMBA starter for ${ORANGE}${BINARY} - ${LIGHT_CONFIG}_ssl_disable - ${LIGHT_LIBS}${NC}"
              "${BUSYBOX}" echo -e -n "${BINARY} -f ${LIGHT_CONFIG}_ssl_disable -m ${LIGHT_LIBS}\n" >> /firmadyne/service
            fi
          done
        done
      # fi
    elif [ "$("${BUSYBOX}" echo "${SERVICE_NAME}")" == "miniupnpd" ]; then
      if ! "${BUSYBOX}" grep -q "${SERVICE_NAME}" /firmadyne/service 2>/dev/null; then
        for MINIUPNPD_CONFIG in $("${BUSYBOX}" find / -name "*miniupnpd*.conf" -type f); do
          "${BUSYBOX}" echo -e "[*] Writing EMBA starter for ${ORANGE}${BINARY} - ${MINIUPNPD_CONFIG}${NC}"
          "${BUSYBOX}" echo -e -n "${BINARY} -f ${MINIUPNPD_CONFIG}\n" >> /firmadyne/service
        done
        "${BUSYBOX}" echo -e -n "${BINARY} -p 9875 -a 0.0.0.0 -i eth0 -d\n" >> /firmadyne/service
      fi
    elif [ "$("${BUSYBOX}" echo "${SERVICE_NAME}")" == "wscd" ]; then
      if ! "${BUSYBOX}" grep -q "${SERVICE_NAME}" /firmadyne/service 2>/dev/null; then
        for WSCD_CONFIG in $("${BUSYBOX}" find / -name "*wscd*.conf" -type f); do
          "${BUSYBOX}" echo -e "[*] Writing EMBA starter for ${ORANGE}${BINARY} - ${WSCD_CONFIG}${NC}"
          "${BUSYBOX}" echo -e -n "${BINARY} -c ${WSCD_CONFIG}\n" >> /firmadyne/service
          "${BUSYBOX}" echo -e -n "${BINARY} -c ${WSCD_CONFIG} -mode 1 -upnp 1 -daemon\n" >> /firmadyne/service
        done
        "${BUSYBOX}" echo -e -n "${BINARY} -a 0.0.0.0 -m 3 -D -d 3\n" >> /firmadyne/service
      fi
    elif [ "$("${BUSYBOX}" echo "${SERVICE_NAME}")" == "upnp" ]; then
      if ! "${BUSYBOX}" grep -q "${SERVICE_NAME}" /firmadyne/service 2>/dev/null; then
        "${BUSYBOX}" echo -e "[*] Writing EMBA starter for ${ORANGE}${BINARY}${NC}"
        "${BUSYBOX}" echo -e -n "${BINARY}\n" >> /firmadyne/service
        "${BUSYBOX}" echo -e "[*] Writing EMBA starter for ${ORANGE}${BINARY} -L eth0 -W eth0${NC}"
        "${BUSYBOX}" echo -e -n "${BINARY} -L eth0 -W eth0\n" >> /firmadyne/service
      fi
    elif [ "$("${BUSYBOX}" echo "${SERVICE_NAME}")" == "upnpd" ]; then
      if ! "${BUSYBOX}" grep -q "${SERVICE_NAME}" /firmadyne/service 2>/dev/null; then
        "${BUSYBOX}" echo -e "[*] Writing EMBA starter for ${ORANGE}${BINARY}${NC}"
        "${BUSYBOX}" echo -e -n "${BINARY}\n" >> /firmadyne/service

        # let's try upnpd with a basic configuration:
        "${BUSYBOX}" echo -e "[*] Writing EMBA starter for ${ORANGE}${BINARY} ppp0 eth0${NC}"
        "${BUSYBOX}" echo -e -n "${BINARY} ppp0 eth0\n" >> /firmadyne/service
        "${BUSYBOX}" echo -e -n "${BINARY} eth0 eth0\n" >> /firmadyne/service
      fi
    elif [ "$("${BUSYBOX}" echo "${SERVICE_NAME}")" == "ftpd" ]; then
      if ! "${BUSYBOX}" grep -q "${SERVICE_NAME}" /firmadyne/service 2>/dev/null; then
        "${BUSYBOX}" echo -e "[*] Writing EMBA starter for ${ORANGE}${BINARY}${NC}"
        "${BUSYBOX}" echo -e -n "${BINARY} -D\n" >> /firmadyne/service
      fi
    elif [ "$("${BUSYBOX}" echo "${SERVICE_NAME}")" == "miniigd" ]; then
      if ! "${BUSYBOX}" grep -q "${SERVICE_NAME}" /firmadyne/service 2>/dev/null; then
        "${BUSYBOX}" echo -e "[*] Writing EMBA starter for ${ORANGE}${BINARY}${NC}"
        "${BUSYBOX}" echo -e -n "${BINARY} -i eth0 -a 0.0.0.0 -p 49156\n" >> /firmadyne/service
      fi
    fi
    # this is the default case - without config but only if the service is not already in the service file
    if ! "${BUSYBOX}" grep -q "${SERVICE_NAME}" /firmadyne/service 2>/dev/null; then
      "${BUSYBOX}" echo -e "[*] Writing EMBA starter for ${ORANGE}${BINARY}${NC}"
      "${BUSYBOX}" echo -e -n "${BINARY}\n" >> /firmadyne/service
    fi

    # other rules we need to apply
    if [ "$("${BUSYBOX}" echo "${SERVICE_NAME}")" == "twonkystarter" ]; then
      "${BUSYBOX}" mkdir -p /var/twonky/twonkyserver
    fi
  fi
done

"${BUSYBOX}" echo -e "[*] Writing EMBA service for the ${ORANGE}EMBA netcat listener${NC}"
"${BUSYBOX}" echo -e -n "/firmadyne/netcat -nvlp 9876 -e /firmadyne/sh\n" >> /firmadyne/service
"${BUSYBOX}" echo -e "[*] Writing EMBA service for the ${ORANGE}EMBA telnet listener${NC}"
"${BUSYBOX}" echo -e -n "/firmadyne/busybox telnetd -p 9877 -l /firmadyne/sh\n" >> /firmadyne/service

if [ -f /firmadyne/service ]; then
  "${BUSYBOX}" sort -u -o /firmadyne/service /firmadyne/service
fi

"${BUSYBOX}" echo "[*] EMBA inferService script finished ..."
