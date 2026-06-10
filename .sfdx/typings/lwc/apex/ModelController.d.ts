declare module "@salesforce/apex/ModelController.getActiveModels" {
  export default function getActiveModels(): Promise<any>;
}
declare module "@salesforce/apex/ModelController.getVariantsByModel" {
  export default function getVariantsByModel(param: {modelId: any}): Promise<any>;
}
declare module "@salesforce/apex/ModelController.getModelById" {
  export default function getModelById(param: {modelId: any}): Promise<any>;
}
declare module "@salesforce/apex/ModelController.getCitiesByModel" {
  export default function getCitiesByModel(param: {modelId: any}): Promise<any>;
}
declare module "@salesforce/apex/ModelController.getActiveModelsWithVariants" {
  export default function getActiveModelsWithVariants(): Promise<any>;
}
