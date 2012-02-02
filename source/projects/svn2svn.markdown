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
- Meant for replaying history into an **empty** target location. This could be
  an empty target repo or simply a brand-new folder/branch in the target repo.
- Maintains logical history (when possible), e.g. uses "svn copy" for renames.
- Maintains original commit messages.
    - Optionally maintain source author info. (Only supported if target SVN
      repo doesn't require auth, since this relies upon the `--username`
      command-line arg.)
    - **Note:** Cannot maintain original commit date, but appends original
      commit date for each commit message: "Date: %d".
- Optionally run an external shell script before each replayed commit
  to give the ability to dynamically exclude or modify files as part
  of the replay.

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
generating new commits which will have newer commit-dates and revision #'s.

Usage
-----
See `svn2svn.py --help`

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
* Project home: [http://nynim.org/projects/svn2svn](http://nynim.org/projects/svn2svn)
* Github: [https://github.com/tonyduckles/svn2svn](https://github.com/tonyduckles/svn2svn)
* Git @ nynim.org [http://git.nynim.org/svn2svn.git](http://git.nynim.org/svn2svn.git)
