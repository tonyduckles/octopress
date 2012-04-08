---
layout: page
title: svn2svn
comments: false
sharing: true
footer: true
---

Replicate (replay) changesets from one Subversion repository to another.

Features
--------
- **Meant for replaying history into an "empty target location**. This could be
  an empty target repo or simply an empty folder/branch in the target repo.
- **Maintains logical history (ancestry) when possible**, e.g. uses "svn copy"
  for renames.
- **Maintains original commit messages**.
- **Optionally maintain source commit authors (`svn:author`) and commit timestamps
  (`svn:date`)**.  Requires a "pre-revprop-change" hook script in the target
  repo, to be able to change the "`svn:author`" and "`svn:date`" revprops after
  target commits have been made.
- **Optionally maintain identical revision #'s between source vs. target repo**.
  Effectively requires that you're replaying into an empty target repo,
  or rather that the first source repo revision to be replayed is less than
  the last target repo revision. Create blank "padding" revisions in the target
  repo as needed.
- **Optionally run an external shell script before each replayed commit**,
  to give the ability to dynamically exclude or modify files as part
  of the replay.

Requirements
------------
- **Python 2.6** or higher.
- **Subversion 1.6** or higher.
- Written for a UNIX-type environment, e.g. Linux, Mac OSX, etc. For
  Windows-based usage, recommend using [Cygwin](http://www.cygwin.com/) for
  best compatibility.

Overview
--------
This is a utility for replicating the revision history from a source path in
a source SVN repository to a target path in a target SVN repository. In other
words, it "replays the history" of a given source SVN repository/branch/path
into a target SVN repository/branch/path.

This can be useful to create filtered version of a source SVN repository. For
example, say that you have a huge SVN repository with a _lot_ of old branch
history which is taking up a lot of disk-space and not serving a lot of purpose
going forward.  You can this utility to replay/filter just the "/trunk" SVN
history into a new repository, so that things like "svn log" and "svn blame"
will still show the correct (logical) history/ancestry, even though we end-up
generating new commits which will have newer commit-dates and revision #'s
(_though this script can optionally maintain the original commit-dates and
revision #'s if desired_).

While this replay process will obviously run faster if you're running between
both a local source and target repositories, none of this *requires* direct
access to the repo server. You could access both the source and target repo's
over standard `http://`, `svn://`, `svn+ssh://`, etc. methods.

Usage
-----
See `svn2svn.py --help`:

    $ ./svn2svn.py --help
    svn2svn, version 1.5.0
    <http://nynim.org/projects/svn2svn> <https://github.com/tonyduckles/svn2svn>
    
    Usage: svn2svn.py [OPTIONS] source_url target_url
    
    Replicate (replay) history from one SVN repository to another. Maintain
    logical ancestry wherever possible, so that 'svn log' on the replayed repo
    will correctly follow file/folder renames.
    
    Examples:
      Create a copy of only /trunk from source repo, starting at r5000
      $ svnadmin create /svn/target
      $ svn mkdir -m 'Add trunk' file:///svn/target/trunk
      $ svn2svn -av -r 5000 http://server/source/trunk file:///svn/target/trunk
        1. The target_url will be checked-out to ./_wc_target
        2. The first commit to http://server/source/trunk at/after r5000 will be
           exported & added into _wc_target
        3. All revisions affecting http://server/source/trunk (starting at r5000)
           will be replayed to _wc_target. Any add/copy/move/replaces that are
           copy-from'd some path outside of /trunk (e.g. files renamed on a
           /branch and branch was merged into /trunk) will correctly maintain
           logical ancestry where possible.
    
      Use continue-mode (-c) to pick-up where the last run left-off
      $ svn2svn -avc http://server/source/trunk file:///svn/target/trunk
        1. The target_url will be checked-out to ./_wc_target, if not already
           checked-out
        2. All new revisions affecting http://server/source/trunk starting from
           the last replayed revision to file:///svn/target/trunk (based on the
           svn2svn:* revprops) will be replayed to _wc_target, maintaining all
           logical ancestry where possible.
    
    Options:
          --version       show program's version number and exit
      -h, --help          show this help message and exit
      -v, --verbose       enable additional output (use -vv or -vvv for more)
      -a, --archive       archive/mirror mode; same as -UDP (see REQUIRE's below)
                          maintain same commit author, same commit time, and
                          file/dir properties
      -U, --keep-author   maintain same commit authors (svn:author) as source
                          (REQUIRES 'pre-revprop-change' hook script to allow
                          'svn:author' changes)
      -D, --keep-date     maintain same commit time (svn:date) as source
                          (REQUIRES 'pre-revprop-change' hook script to allow
                          'svn:date' changes)
      -P, --keep-prop     maintain same file/dir SVN properties as source
      -R, --keep-revnum   maintain same rev #'s as source. creates placeholder
                          target revisions (by modifying a 'svn2svn:keep-revnum'
                          property at the root of the target repo)
      -c, --continue      continue from last source commit to target (based on
                          svn2svn:* revprops)
      -f, --force         allow replaying into a non-empty target folder
      -r, --revision=ARG  revision range to replay from source_url
                          A revision argument can be one of:
                             START        start rev # (end will be 'HEAD')
                             START:END    start and ending rev #'s
                          Any revision # formats which SVN understands are
                          supported, e.g. 'HEAD', '{2010-01-31}', etc.
      -u, --log-author    append source commit author to replayed commit mesages
      -d, --log-date      append source commit time to replayed commit messages
      -l, --limit=NUM     maximum number of source revisions to process
      -n, --dry-run       process next source revision but don't commit changes to
                          target working-copy (forces --limit=1)
      -x, --verify        verify ancestry and content for changed paths in commit
                          after every target commit or last target commit
      -X, --verify-all    verify ancestry and content for entire target_url tree
                          after every target commit or last target commit
          --debug         enable debugging output (same as -vvv)

Side Effects
------------
- The source repo is treated as strictly read-only. We do log/info/export/etc.
  actions from the source repo, to get the history to replay and to get the
  file contents at each step along teh way.
- You must have commit access to the target repo. Additionally, for some of
  the optional command-line args, you'll need access to the target repo to
  setup hook scripts, e.g. "pre-revprop-change".
- This script will create some folders off of your current working directory:
  - "`_wc_target`": This is the checkout of the target\_url, where we replay
    actions into and where we commit to the target repo. You can safely
    remove this directory after a run, and the script will do a fresh
    "svn checkout" (if needed) when starting the next time.
  - "`_wc_target_tmp`": This is a temporary folder, which will only be created
    if using `--keep-revnum` mode and it should only exist for brief periods
    of time. This is where we commit dummy/padding revisions to the target repo,
    checking out the root folder of the target repo and modifying a
    "`svn2svn:keep-revnum`" property, i.e. a small change to trigger a commit
    and in a location that will likely go un-noticed in the final target repo.

Examples
--------
**Create a copy of only /trunk from source repo, starting at r5000**

    $ svnadmin create /svn/target
    $ svn mkdir -m 'Add trunk' file:///svn/target/trunk
    $ svn2svn -av -r 5000 http://server/source/trunk file:///svn/target/trunk

1. The `target_url` will be checked-out to `./_wc_target`.
2. The first commit to `http://server/source/trunk` at/after r5000 will be
   exported & added into `_wc_target`.
3. All revisions affecting `http://server/source/trunk` (starting at r5000)
   will be replayed to `_wc_target`. Any add/copy/move/replaces that are
   copy-from'd some path outside of /trunk (e.g. files renamed on a
   /branch and branch was merged into /trunk) will correctly maintain
   logical ancestry where possible.

**Use continue-mode (-c) to pick-up where the last run left-off**

    $ svn2svn -avc http://server/source/trunk file:///svn/target/trunk

1. The `target_url` will be checked-out to `./_wc_target`, if not already
   checked-out
2. All new revisions affecting `http://server/source/trunk` starting from
   the last replayed revision to `file:///svn/target/trunk` (based on the
   "`svn2svn:*`" revprops) will be replayed to `_wc_target`, maintaining all
   logical ancestry where possible.

Credits
-------
This project borrows a lot of code from the "hgsvn" project.  Many thanks to
the folks who have contributed to the hgsvn project, for writing code that is
easily re-usable:

* [http://pypi.python.org/pypi/hgsvn](http://pypi.python.org/pypi/hgsvn)
* [https://bitbucket.org/andialbrecht/hgsvn/overview](https://bitbucket.org/andialbrecht/hgsvn/overview)

This project was originally inspired by this "svn2svn" project:  
[http://code.google.com/p/svn2svn/](http://code.google.com/p/svn2svn/)  
That project didn't fully meet my needs, so I forked and ended-up rewriting
the majority of the code.

Links
-----
* Introduction: "**[svn2svn: Replaying SVN History](http://nynim.org/blog/2012/02/01/svn2svn-replaying-svn-history/)**"
* Project page: [http://nynim.org/projects/svn2svn](http://nynim.org/projects/svn2svn)
* Source code @ Github: [https://github.com/tonyduckles/svn2svn](https://github.com/tonyduckles/svn2svn)
* Source code @ git.nynim.org [http://git.nynim.org/svn2svn.git](http://git.nynim.org/svn2svn.git)
