#!/bin/bash
dpkg --get-selections | grep -v deinstall | awk '{print $1}'
