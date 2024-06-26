# VZIC README

This is `vzic`, a program to convert the IANA (formerly Olson)
timezone database files into VTIMEZONE files compatible with the
iCalendar specification (RFC2445).

(The name is based on the `zic` program which converts the IANA files into
time zone information files used by several Unix C libraries, including
glibc. See zic(8) and tzfile(5).)

The vzic software is licensed according to the terms of the
GNU General Public License version 2.0 or later (see LICENSES/GPL-2.0-or-later.txt).
The IANA timezone database files are in the public domain.

## REQUIREMENTS

You need the IANA (formerly known as Olson) timezone database files (tzdata),
which  can be found at:

  <http://www.iana.org/time-zones>

Vzic also uses the GLib library (for hash tables, dynamic arrays, and date
calculations). You need version 2.0 or higher. You can get this from:

  <http://www.gtk.org>

## PREPARATIONS

gunzip and untar the tzdata file:

```bash
  % mkdir tzdata2014g
  % cd  tzdata2014g; tar xvfz ../tzdata2014g.tar.gz; cd ..
```

## BUILDING

Edit the Makefile to set the OLSON_DIR (in this case to tzdata2014g),
PRODUCT_ID and TZID_PREFIX variables.

Then run `make -B`.

## RUNNING

Run `./vzic`

The output is placed in the zoneinfo subdirectory by default,
but you can use the --output-dir options to set another toplevel output
directory.

By default it outputs VTIMEZONEs that try to be compatible with Outlook
(2000, at least). Outlook can't handle certain iCalendar constructs in
VTIMEZONEs, such as RRULEs using BYMONTHDAY, so it has to adjust the RRULEs
slightly to get Outlook to parse them. Unfortunately this means they are
slightly wrong. If given the --pure option, vzic outputs the exact data,
without worrying about compatibility.

NOTE: We don't convert all the IANA files. We skip 'backward', 'etcetera',
'leapseconds', 'pacificnew', 'solar87', 'solar88' and 'solar89', 'factory'
and 'systemv', since these don't really provide any useful timezones.
See vzic.c.

## MERGING CHANGES INTO A MASTER SET OF VTIMEZONES

The IANA timezone files are updated fairly often, so we need to build new
sets of VTIMEZONE files. Though we have to be careful to ensure that the TZID
of updated timezones is also updated, since it must remain unique.

We use a version number on the end of the TZID prefix (see the TZIDPrefix
variable in vzic-output.c) to ensure this uniqueness.

But we don't want to update the version numbers of VTIMEZONEs which have not
changed. So we use the vzic-merge.pl Perl script. This merges in the new set
of VTIMEZONEs with a 'master' set. It compares each new VTIMEZONE file with
the one in the master set (ignoring changes to the TZID). If the new
VTIMEZONE file is different, it copies it to the master set and sets the
version number to the old VTIMEZONE's version number + 1.

To use vzic-merge.pl you must change the $MASTER_ZONEINFO_DIR and
$NEW_ZONEINFO_DIR variables at the top of the file to point to your 2 sets of
VTIMEZONEs. You then just run the script. (I recommend you keep a backup of
the old master VTIMEZONE files, and use diff to compare the new master set
with the old one, in case anything goes wrong.)

You must add the new timezones in the zones.tab file by hand.
diff the new zones.tab versus the current zones.tab

Note that some timezones are renamed or removed occasionally, so applications
should be able to cope with this.

## COMPATIBILITY NOTES

It seems that Microsoft Outlook is very picky about the iCalendar files it
will accept. (I've been testing with Outlook 2000. I hope the other versions
are no worse.) Here's a few problems we've had with the VTIMEZONEs:

 o Outlook doesn't like any years before 1600. We were using '1st Jan 0001'
   in all VTIMEZONEs to specify the first UTC offset known for the timezone.
   (The IANA data does not give a start date for this.)

   Now we just skip this first component for most timezones. The UTC offset
   can still be found from the TZOFFSETFROM property of the first component.

   Though some timezones only specify one UTC offset that applies forever,
   so in these cases we output '1st Jan 1970' (Indian/Cocos,
   Pacific/Johnston).

 o Outlook doesn't like the BYMONTHDAY specifier in RRULEs.

   We have changed most of the VTIMEZONEs to use things like 'BYDAY=2SU'
   rather than 'BYMONTHDAY=8,9,10,11,12,13,14;BYDAY=SU', though some of
   them were impossible to convert correctly so they are not always correct.

 o Outlook doesn't like TZOFFSETFROM/TZOFFSETTO properties which include a
   seconds component, e.g. 'TZOFFSETFROM:+110628'.
   Quite a lot of the IANA timezones include seconds in their UTC offsets,
   though no timezones currently have a UTC offset that uses the seconds
   value.

   We've rounded all UTC offsets to the nearest minute. Since all timezone
   offsets currently used have '00' as the seconds offset, this doesn't lose
   us much.

 o Outlook doesn't like lines being split in certain places, even though
   the iCalendar spec says they can be split anywhere.

 o Outlook can only handle one RDATE or a pair of RRULEs. So we had to remove
   all historical data.

## TESTING

Do a `make test-vzic`, then run `./test-vzic`.

The test-vzic program compares our libical code and VTIMEZONE data against
the Unix functions like mktime(). It steps over a period of time (1970-2037)
converting from UTC to a given timezone and back again every 15 minutes.
Any differences are output into the test-output directory.

The output matches for all of the timezones, except in a few places where the
result can't be determined. So I think we can be fairly confident that the
VTIMEZONEs are correct.

Note that you must use the same IANA data in libical that the OS is using
for mktime() etc. For example, I am using RedHat 9 which uses tzdata2002d,
so I converted this to VTIMEZONE files and installed it into the libical
timezone data directory before testing. (You need to use '--pure' when
creating the VTIMEZONE files as well.)

### Testing the Parsing Code

Run `make test-parse`.

This runs `vzic --dump` and `perl-dump` and compares the output. The diff
commands should not produce any output.

`vzic --dump` dumps all the parsed data out in the original Olson format,
but without comments. The files are written into the ZonesVzic and RulesVzic
subdirectories of the zoneinfo directory.

`make perl-dump` runs the vzic-dump.pl perl script which outputs the files
in the same format as `vzic --dump` in the ZonesPerl and RulesPerl
subdirectories. The perl script doesn't actually parse the fields; it only
strips comments and massages the fields so we have the same output format.

Currently they both produce exactly the same output so we know the parsing
code is OK.

### Testing the VTIMEZONE Files

Run `make test-changes`.

This runs `vzic --dump-changes` and `test-vzic --dump-changes` and compares
the output. The diff command should not produce any output.

Both commands output timezone changes for each zone up to a specific year
(2030) into files for each timezone. It outputs the timezone changes in a
list in this format:

```text
  Timezone Name        Date and Time of Change in UTC   New Offset from UTC

  America/Dawson       26 Oct 1986 2:00:00              -0800
```

Unfortunately there are some differences here, but they all happen before
1970 so it doesn't matter too much. It looks like the libical code has
problems determining things like 'last Sunday of the month' before 1970.
This is because it uses mktime() etc. which can't really handle dates
before 1970.

Damon Chaplin <damon@gnome.org>, 25 Oct 2003.
