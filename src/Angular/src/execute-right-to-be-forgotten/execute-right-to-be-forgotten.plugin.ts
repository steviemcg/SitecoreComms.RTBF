import { Plugin } from '@sitecore/ma-core';
import { ExecuteRightToBeForgottenActivity } from './execute-right-to-be-forgotten-activity';
import { ExecuteRightToBeForgottenModuleNgFactory } from '../../codegen/execute-right-to-be-forgotten/execute-right-to-be-forgotten-module.ngfactory';
import { ExecuteRightToBeForgottenEditorComponent } from '../../codegen/execute-right-to-be-forgotten/execute-right-to-be-forgotten-editor.component';
 
@Plugin({
    activityDefinitions: [
        {
            id: 'b4df14da-e09d-406d-b742-c33ea465068e',
            activity: ExecuteRightToBeForgottenActivity,
            editorComponenet: ExecuteRightToBeForgottenEditorComponent,
            editorModuleFactory: ExecuteRightToBeForgottenModuleNgFactory
        }
    ]
})

export default class ExecuteRightToBeForgottenPlugin {}