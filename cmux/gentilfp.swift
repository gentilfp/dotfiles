// gentilfp — worktrees + agent strip
//
// Constraints learned the hard way, don't undo these:
//   · No top-level `let` using .sorted/.filter — silently yields nothing.
//     Counts come from builtins (workspaceCount, unreadTotal) only.
//   · Filtering is an `if` inside a ForEach body, never .filter{} on the array.
//   · Agent tabs rename themselves to the task ("✱ Fix Rails Admin strftime"),
//     so agents are detected by EXCLUDING tools/shells, not matching names.
//   · Spacer() does not expand here, so AGENTS sits below the list, not pinned.
//
// edit + save = hot reload.  cmux sidebar select gentilfp

VStack(alignment: .leading, spacing: 0) {

    // ───────────────────────────────── workspaces
    //
    // Your layout, from `git worktree list`:
    //   main repo   ~/Developer/<repo>
    //   worktree    ~/Developer/.worktrees/<repo>/<branch>
    //
    // So for a worktree path, dropFirst(4) skips Users/<you>/Developer/.worktrees
    // and lands on <repo>, while .last is the branch. For a main-repo path,
    // .last is the repo itself. The 4 is tied to ~/Developer being 3 deep —
    // if you ever move your code root, that's the number to change.
    HStack {
        Text("Workspaces")
            .font(.system(size: 9))
            .fontWeight(.semibold)
            .textCase(.uppercase)
            .foregroundColor(.secondary)
        Spacer()
        Text("\(workspaceCount)")
            .font(.system(size: 9, design: .monospaced))
            .foregroundColor(.tertiary)
    }
    .padding(6)

    Divider()

    Reorderable(workspaces, move: "workspace.reorder") { w in
        Button(action: { cmux("workspace.select", workspace_id: w.id) }) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                // Type icon (SF Symbol), coloured by selection:
                //   worktree -> branch glyph, main repo -> folder, else -> terminal
                Image(systemName: w.directory.contains("/.worktrees/") ? "arrow.triangle.branch" : (w.directory.contains("/Developer/") ? "folder.fill" : "terminal.fill"))
                    .font(.system(size: 10))
                    .foregroundColor(w.selected ? "#3FB950" : .secondary)

                VStack(alignment: .leading, spacing: 1) {
                    // Everything here comes from w.directory: the interpreted
                    // sidebar does NOT receive w.branch / w.description / w.color
                    // (they arrive nil), so paths are all we have. Layout, from
                    //   main repo   ~/Developer/<repo>
                    //   worktree    ~/Developer/.worktrees/<repo>/<branch>
                    //
                    // TOP line = the repo ("folder"). For a worktree that's the
                    // 5th path segment (dropFirst(4).first); for a main repo it's
                    // the last segment; otherwise the workspace title.
                    Text(w.directory.contains("/.worktrees/") ? String(w.directory.split(separator: "/").dropFirst(4).first) : (w.directory.contains("/Developer/") ? String(w.directory.split(separator: "/").last) : w.title))
                        .font(.system(size: 12))
                        .fontWeight(w.selected ? .semibold : .regular)
                        .foregroundColor(w.selected ? .primary : .secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    // SECOND line — always present so every row is the same
                    // height (keeps the icon aligned). A worktree shows └ + its
                    // branch (the dir name); a main can't show a branch
                    // (not in the path, not in the DSL) so it shows "⌂ main
                    // checkout"; anything else shows its folder name.
                    Text(w.directory.contains("/.worktrees/") ? ("└ " + String(w.directory.split(separator: "/").last)) : (w.directory.contains("/Developer/") ? "⌂ main" : ("⌂ " + String(w.directory.split(separator: "/").last))))
                        .font(.system(size: 9))
                        .foregroundColor(w.directory.contains("/.worktrees/") ? "#7EE3F5" : .tertiary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()

                // pinned marker (only when pinned)
                if w.pinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 8))
                        .foregroundColor("#8E8E93")
                }

                Text(w.unread > 0 ? "\(w.unread)" : "")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor("#F5A623")
            }
            .padding(5)
            // Selected-row highlight: a subtle rounded background.
            .background(RoundedRectangle(cornerRadius: 6).fill(w.selected ? "#2A2F37" : .clear))
        }
        // Right-click actions. Colour is intentionally omitted — this sidebar
        // can't render w.color, so it would have no visible effect here.
        .contextMenu {
            if w.pinned {
                Button(action: { cmux("workspace.action", workspace_id: w.id, action: "unpin") }) { Text("Unpin") }
            } else {
                Button(action: { cmux("workspace.action", workspace_id: w.id, action: "pin") }) { Text("Pin to top") }
            }
            Button(action: { cmux("workspace.close", workspace_id: w.id) }) { Text("Close workspace") }
        }
        .help(w.directory)
    }

    Spacer()

    Divider()

    // ───────────────────────────────── agents
    HStack {
        Text("Agents")
            .font(.system(size: 9))
            .fontWeight(.semibold)
            .textCase(.uppercase)
            .foregroundColor(.secondary)
        Spacer()
        Text(unreadTotal > 0 ? "\(unreadTotal) waiting" : "")
            .font(.system(size: 9, design: .monospaced))
            .foregroundColor("#F5A623")
    }
    .padding(6)

    ForEach(workspaces.prefix(6)) { w in
        ForEach(w.tabs.prefix(8)) { t in
            // add tools here as you hit them
            if !t.title.contains("/") && !t.title.contains("~") && !t.title.contains("vim") && !t.title.contains("lazygit") && !t.title.contains("hunk") && !t.title.contains("btop") && !t.title.contains("htop") {
                Button(action: { cmux("surface.focus", surface_id: t.id) }) {
                    HStack(spacing: 6) {
                        Text(w.unread > 0 ? "◉" : (w.progress != nil ? "●" : (t.focused ? "●" : "○")))
                            .font(.system(size: 9))
                            .foregroundColor(w.unread > 0 ? "#F5A623" : (w.progress != nil ? "#3FB950" : (t.focused ? .primary : .secondary)))

                        Text(t.title)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(t.focused ? .primary : .secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Spacer()

                        // project/folder name: worktree -> repo name (same derivation
                        // as the workspace list's top line), everything else -> last
                        // path segment (so paths outside ~/Developer still show a folder)
                        Text(w.directory.contains("/.worktrees/") ? String(w.directory.split(separator: "/").dropFirst(4).first) : String(w.directory.split(separator: "/").last))
                            .font(.system(size: 9))
                            .foregroundColor(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .padding(5)
                }
                .help(t.title)
            }
        }
    }
}
