import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import models.{type Comment, type CommentWithChildren, CommentWithChildren}

// Comment with all its descendants recursively nested

// Build comment tree - returns only root comments with all descendants nested
pub fn build_comment_tree(comments: List(Comment)) -> List(CommentWithChildren) {
  // Group comments by parent_id for O(1) lookup
  let children_map = group_by_parent(comments)

  // Find root comments (those with no parent)
  let root_comments =
    list.filter(comments, fn(c) { c.parent_comment_id == None })

  // Build tree recursively for each root comment
  list.map(root_comments, fn(root) { build_tree(root, children_map) })
}

// Helper: Group comments by their parent_comment_id
fn group_by_parent(comments: List(Comment)) -> Dict(String, List(Comment)) {
  list.fold(comments, dict.new(), fn(acc, comment) {
    case comment.parent_comment_id {
      None -> acc
      Some(parent_id) -> {
        let existing = dict.get(acc, parent_id) |> option.unwrap([])
        dict.insert(acc, parent_id, [comment, ..existing])
      }
    }
  })
}

// Helper: Recursively build tree for a comment and all its descendants
fn build_tree(
  comment: Comment,
  children_map: Dict(String, List(Comment)),
) -> CommentWithChildren {
  // Get direct children of this comment
  let direct_children =
    dict.get(children_map, comment.id)
    |> option.unwrap([])

  // Recursively build trees for each child
  let children_trees =
    list.map(direct_children, fn(child) { build_tree(child, children_map) })

  CommentWithChildren(comment, children_trees)
}
