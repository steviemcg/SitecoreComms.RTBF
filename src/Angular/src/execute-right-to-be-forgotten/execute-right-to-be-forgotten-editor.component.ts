import { Component, Injector, OnInit } from '@angular/core';
import { EditorBase } from '@sitecore/ma-core';

@Component({
    selector: 'ma-export-right-to-be-forgotten-editor',
    template: `
        <section class="content">
            <div class="form-group">
                <div class="row readonly-editor">
                    <label class="col-6 title"></label>
                    <div class="col-6">
						
                    </div>
                </div>
            </div>
        </section>
    `,
    styles: ['']
})
export class ExecuteRightToBeForgottenEditorComponent extends EditorBase implements OnInit {
    constructor(private injector: Injector) {
        super();
    }

    ngOnInit(): void {
    }

    serialize(): any {
        return {
        };
    }
}