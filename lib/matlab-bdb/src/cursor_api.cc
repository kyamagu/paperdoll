/// Berkeley DB cursor mex interface.
///
/// Kota Yamaguchi 2012 <kyamagu@cs.stonybrook.edu>

#include "libbdbmex.h"
#include "mex/arguments.h"
#include "mex/function.h"
#include "mex/mxarray.h"

using bdbmex::Cursor;
using bdbmex::Database;
using mex::CheckInputArguments;
using mex::CheckOutputArguments;
using mex::MxArray;
using mex::Session;

namespace {

MEX_FUNCTION(cursor_open) (int nlhs,
                           mxArray *plhs[],
                           int nrhs,
                           const mxArray *prhs[]) {
  CheckInputArguments(0, 1, nrhs);
  CheckOutputArguments(0, 1, nlhs);
  int database_id = (nrhs == 0) ? 0 : MxArray(prhs[0]).toInt();
  Database* database = Session<Database>::get(database_id);
  Cursor* cursor = NULL;
  int cursor_id = Session<Cursor>::create(&cursor);
  if (!database->cursor(cursor)) {
    Session<Cursor>::destroy(cursor_id);
    ERROR("Unable to open cursor for database: %d", database_id);
  }
  plhs[0] = MxArray(cursor_id).getMutable();
}

MEX_FUNCTION(cursor_close) (int nlhs,
                            mxArray *plhs[],
                            int nrhs,
                            const mxArray *prhs[]) {
  CheckInputArguments(1, 1, nrhs);
  CheckOutputArguments(0, 0, nlhs);
  int cursor_id = MxArray(prhs[0]).toInt();
  Session<Cursor>::destroy(cursor_id);
}

MEX_FUNCTION(cursor_next) (int nlhs,
                           mxArray *plhs[],
                           int nrhs,
                           const mxArray *prhs[]) {
  CheckInputArguments(1, 1, nrhs);
  CheckOutputArguments(0, 1, nlhs);
  Cursor* cursor = Session<Cursor>::get(MxArray(prhs[0]).toInt());
  int code = cursor->next();
  if (code == 0)
    plhs[0] = MxArray(true).getMutable();
  else if (code == DB_NOTFOUND)
    plhs[0] = MxArray(false).getMutable();
  else
    ERROR("Failed to move a cursor: %s", cursor->error_message());
}

MEX_FUNCTION(cursor_prev) (int nlhs,
                           mxArray *plhs[],
                           int nrhs,
                           const mxArray *prhs[]) {
  CheckInputArguments(1, 1, nrhs);
  CheckOutputArguments(0, 1, nlhs);
  Cursor* cursor = Session<Cursor>::get(MxArray(prhs[0]).toInt());
  int code = cursor->prev();
  if (code == 0)
    plhs[0] = MxArray(true).getMutable();
  else if (code == DB_NOTFOUND)
    plhs[0] = MxArray(false).getMutable();
  else
    ERROR("Failed to move a cursor: %s", cursor->error_message());
}

MEX_FUNCTION(cursor_get) (int nlhs,
                          mxArray *plhs[],
                          int nrhs,
                          const mxArray *prhs[]) {
  CheckInputArguments(1, 1, nrhs);
  CheckOutputArguments(0, 2, nlhs);
  Cursor* cursor = Session<Cursor>::get(MxArray(prhs[0]).toInt());
  if (cursor->error_code() != 0)
    ERROR("Failed to get from cursor: %s", cursor->error_message());
  cursor->get()->get_key(&plhs[0]);
  if (nlhs > 1)
    cursor->get()->get_value(&plhs[1]);
}

} // namespace