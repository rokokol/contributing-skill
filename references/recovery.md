# Recovery

`contrib.sh` prints the safe next action when a draft cannot proceed. This reference explains the states behind those diagnostics; it does not replace them

The approval hash binds one approval to the stored bytes and draft ID, not to the honesty of the agent that prints and submits it. The user reading the whole card is the guard against a dishonest or mistaken agent, so a summary, test result or another agent's review never substitutes for showing it

## Stale draft

Exit 4 means the approved card no longer describes the world or the stored bytes: the draft changed, a branch or pull request head moved, a remote resolves elsewhere, or the text to edit was replaced. Nothing was published, and the claimed directory is handed back as an ordinary waiting draft

Drop that draft, make a new one from current state, show the entire new card and obtain a new approval. An old approval never carries over, even when the visible change looks harmless

A draft the user turns down is also dropped rather than kept for a later send. `contrib.sh drafts` lists waiting drafts without their approval hashes; only a card shown to the user carries one

## Interrupted send

Once `.writing` exists, the next GitHub or git call may have taken effect even when the client returned failure. The draft remains under `state/drafts/.sending-ID/` because handing it back would make a second send possible

Check the destination named on the approved card directly on GitHub, using a read-only query when possible. Tell the user whether the action landed, then run `contrib.sh drop ID` to clear the interrupted record. Never run `send` again for that ID: if the action did not land, make a new draft and obtain a new approval

`contrib.sh drafts` identifies every interrupted ID, and attempting to send one prints the same recovery procedure instead of publishing it

## False-positive secret lint

Exit 5 means the proposed body, diff or added file matches a live-secret shape. Remove a real credential and draft again; never add an exclusion or weaken the expression merely to pass a contribution

Removing a leaked credential is not refused because a diff lint reads only added lines

For a documented example, test fixture or other proven false positive, show the refusal and the complete payload to the user, explain why the matched value is not live, and show the exact underlying command before asking for approval. After approval, run exactly that command and verify the destination

For a push, preserve the guarantees the normal publisher would have supplied: use the address, commit and branch shown to the user, and run `git push --no-follow-tags --recurse-submodules=no ADDRESS SHA:refs/heads/BRANCH`. A force-push additionally needs the exact lease shown by the current remote tip; draft again if any of those values moved

This manual path is deliberately exceptional: the approval covers the displayed bytes and command once, and no standing permission bypasses a lint refusal
