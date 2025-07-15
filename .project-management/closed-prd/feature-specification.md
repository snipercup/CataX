There is a bug described as Block build ghost doesn't show when the buildmanager is opened

Steps to reproduce:

- Load a game
- Open build manager
- Observe that concrete_block is observed, but no ghost is shown
- change the selection in the build manager to countertop wood
- observe the ghost is now visible
- change back to concrete block
- observe that the ghost is now visible

The ghost should be visible at the moment that the build manager opens.

This feature will find the cause of the bug and resolve it. In order to do this, we have to diagnose the issue. Find out where the construction ghost visibility is toggled. Check if the construction ghost has a visible texture when it is created. Come up with ways to solve the issue.
