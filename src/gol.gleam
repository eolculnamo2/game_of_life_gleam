import gleam/int
import gleam/list
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html

const interval_ms = 200

const rows = 50

const cols = 20

fn total_cells() -> Int {
  rows * cols
}

fn row_width() -> String {
  rows * 16 |> int.to_string <> "px"
}

fn interval_effect() {
  effect.from(fn(dispatch) {
    set_timeout(
      fn() {
        dispatch(Interval)
        Nil
      },
      interval_ms,
    )
    Nil
  })
}

fn get_neighbor_ids(c: Cell) {
  [
    // top left
    c.id - rows - 1,
    // top mid
    c.id - rows,
    // top right
    c.id - rows + 1,
    // left 
    c.id - 1,
    // right
    c.id + 1,
    // bottom left
    c.id + rows - 1,
    // bottom mid
    c.id + rows,
    // bottom right
    c.id + rows + 1,
  ]
}

@external(javascript, "./ffi.js", "setTimeout")
fn set_timeout(callback: fn() -> Nil, milliseconds: Int) -> Int

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Model(cells: []))

  Nil
}

type Cell {
  Cell(id: Int, is_alive: Bool)
}

type Model {
  Model(cells: List(Cell))
}

fn init(_init: Model) -> #(Model, Effect(Msg)) {
  let cells =
    list.range(0, total_cells() - 1)
    |> list.map(fn(id) { Cell(id: id, is_alive: int.random(100) > 50) })

  #(Model(cells: cells), interval_effect())
}

pub opaque type Msg {
  Interval
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Interval -> {
      let cells =
        model.cells
        |> list.map(fn(c) {
          let total_neighbors =
            get_neighbor_ids(c)
            |> list.fold(0, fn(agg, cur) {
              let neighbor = model.cells |> list.find(fn(c) { c.id == cur })
              case neighbor {
                Ok(Cell(is_alive: alive, ..)) if alive -> agg + 1
                _ -> agg
              }
            })
          Cell(
            ..c,
            is_alive: case total_neighbors, c.is_alive {
              n, True if n < 2 || n > 3 -> False
              n, False if n == 3 -> True
              _, _ -> c.is_alive
            },
          )
        })
      #(Model(cells: cells), interval_effect())
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    html.h1([attribute.class("text-2xl text-center font-semibold")], [
      html.text("Game of life"),
    ]),
    html.div(
      [
        attribute.style([#("max-width", row_width())]),
        attribute.class("flex flex-wrap"),
      ],
      model.cells
        |> list.map(fn(c) {
          html.div(
            [
              attribute.class(
                "h-4 w-4 border border-black "
                <> case c.is_alive {
                  True -> "bg-green-500"
                  False -> "bg-white"
                },
              ),
            ],
            [],
          )
        }),
    ),
  ])
}
