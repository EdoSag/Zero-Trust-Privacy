# Tracker list: where it comes from and its licence

`exodus_trackers.json` is derived from the tracker database of
[Exodus Privacy](https://exodus-privacy.eu.org/), a French non-profit that
studies trackers in Android apps.

- The database is made available under the **Open Database License (ODbL)
  1.0**: <https://opendatacommons.org/licenses/odbl/1-0/>
- Any rights in individual contents of the database are licensed under the
  **Database Contents License (DbCL) 1.0**:
  <https://opendatacommons.org/licenses/dbcl/1-0/>

Exodus Privacy states this in the README files of its `exodus` and `etip`
repositories and in its API documentation.

## What was changed

The file here is an adapted copy. `tool/build_tracker_list.dart` makes it
from the JSON of `https://reports.exodus-privacy.eu.org/api/trackers`:

- kept: each tracker's id, name, categories, website and code signatures;
- left out: descriptions, network signatures, creation dates and
  documentation links, which the app does not use;
- left out: trackers with no code signature, which a scan of code cannot
  find;
- each code signature is split at `|` into plain names.

This adapted file is itself offered under the ODbL 1.0, like the database it
comes from. Anyone may copy it, change it and pass it on under the same
licence, with this credit kept.

The copy the first version was built from came from the copy of that JSON
kept in the TrackerControl project's repository
(`app/src/main/assets/trackers.json`), because the Exodus server could not be
reached from the build machine. Its newest entry is dated 2023-12-05.

## Credit

Tracker definitions derived from the Exodus Privacy database, licensed under
ODbL 1.0. <https://exodus-privacy.eu.org/>

ZT Privacy never calls Exodus Privacy's servers. The list is built into the
app, and no app name leaves the phone during a scan. The one link to them is
a button on a tracker's page in the app: it opens Exodus Privacy's own
description of that tracker in the browser, and only when it is pressed.
