import { SingleItem} from '@sitecore/ma-core';
 
export class ExecuteRightToBeForgottenActivity extends SingleItem {
    getVisual(): string {
        var subTitle = 'Execute Right to be Forgotten';
        return `
            <div class="viewport-export-right-to-be-forgotten-editor marketing-action">
                <span class="icon">
                    <img src="/~/icon/OfficeWhite/32x32/fire.png" />
              </span>
                <p class="text with-subtitle" title="${subTitle}">
                    Execute Right to be Forgotten
                    <small class="subtitle" title="${subTitle}">${subTitle}</small>
                </p>
            </div>
        `;
    }
 
    get isDefined(): boolean {
        return true;
    }
}